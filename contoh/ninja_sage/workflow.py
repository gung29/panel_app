"""Workflow helpers that reproduce the Flash client's AMF call order."""

from __future__ import annotations

import json
from collections.abc import Mapping
from dataclasses import dataclass, field
from typing import Any

from rich.console import Console

from .client import NinjaSageClient
from .constants import DEFAULT_BASE_URL
from .analytics_payload import DEFAULT_ASSET_BASE_URL
from .login_payload import DEFAULT_LIBRARY_URL, LoaderInfo
from .models import (
    AnalyticsLibrariesRequest,
    AnalyticsLibrariesResponse,
    CheckVersionRequest,
    CheckVersionResponse,
    EventCollections,
    EventsServiceGetRequest,
    EventsServiceGetResponse,
    GetAllCharactersRequest,
    GetAllCharactersResponse,
    GetCharacterDataResponse,
    SystemLoginRequest,
    SystemLoginResponse,
    WorkflowResult,
)
from .response_utils import extract_first_body, normalize_content


@dataclass
class Credentials:
    username: str
    password: str


@dataclass
class WorkflowConfig:
    """User provided configuration used to orchestrate the workflow."""

    credentials: Credentials
    base_url: str = DEFAULT_BASE_URL
    channel: str = "Public 0.52"
    include_events: bool = True
    analytics_base_url: str = DEFAULT_ASSET_BASE_URL
    library_url: str = DEFAULT_LIBRARY_URL
    loader: LoaderInfo = field(default_factory=LoaderInfo)
    server_id: int = 12
    selected_character_index: int = 0
    character_seed: int | None = None
    character_key: str | None = None
    events_request: EventsServiceGetRequest = field(default_factory=EventsServiceGetRequest)

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any]) -> "WorkflowConfig":
        credentials_data = payload.get("credentials")
        if not credentials_data:
            raise ValueError("config membutuhkan blok 'credentials' (username & password)")
        loader_data = payload.get("loader_info") or {}
        return cls(
            credentials=Credentials(**credentials_data),
            base_url=payload.get("base_url", DEFAULT_BASE_URL),
            channel=payload.get("channel", "Public 0.52"),
            include_events=payload.get("include_events", True),
            analytics_base_url=payload.get("analytics_base_url", DEFAULT_ASSET_BASE_URL),
            library_url=payload.get("library_url", DEFAULT_LIBRARY_URL),
            loader=LoaderInfo(**loader_data) if loader_data else LoaderInfo(),
            server_id=payload.get("server_id", 12),
            selected_character_index=payload.get("selected_character_index", 0),
            character_seed=payload.get("character_seed"),
            character_key=payload.get("character_key"),
        )

    @classmethod
    def from_file(cls, path: str) -> "WorkflowConfig":
        with open(path, "r", encoding="utf-8") as handle:
            payload = json.load(handle)
        return cls.from_mapping(payload)


class NinjaSageWorkflow:
    """High level API that reproduces the Charles Proxy capture order."""

    def __init__(self, client: NinjaSageClient, config: WorkflowConfig) -> None:
        self.client = client
        self.config = config
        self._response_logger = None

    def _call(self, target: str, body: Sequence[Any], parser):
        # Debug: print outbound body for comparison with Charles
        # print(f"REQUEST {target} body:")
        # print(body)
        envelope = self.client.invoke(target, body=body)
        content = extract_first_body(envelope)
        normalized = normalize_content(content)
        result = parser(normalized)
        print_summary_result = getattr(self, "_response_logger", None)
        if callable(print_summary_result):
            print_summary_result(target, result)
        return result

    def set_response_logger(self, callback):
        """Set a callable ``callback(target: str, parsed_result)`` for each response."""

        self._response_logger = callback

    def run(self) -> WorkflowResult:
        check_version_request = CheckVersionRequest(channel=self.config.channel)
        version = self._call(
            "SystemLogin.checkVersion",
            check_version_request.to_body(),
            CheckVersionResponse.from_content,
        )

        analytics_request = AnalyticsLibrariesRequest.from_assets(self.config.analytics_base_url)
        analytics = self._call(
            "Analytics.libraries",
            analytics_request.to_body(),
            AnalyticsLibrariesResponse.from_content,
        )

        if self.config.include_events:
            events = self._call(
                "EventsService.get",
                self.config.events_request.to_body(),
                EventsServiceGetResponse.from_content,
            )
        else:
            events = EventsServiceGetResponse(status=0, error=0, events=EventCollections())

        seed = self.config.character_seed if self.config.character_seed is not None else version.character_seed
        key = self.config.character_key if self.config.character_key is not None else version.character_key
        if seed is None or key is None:
            raise ValueError(
                "Tidak menemukan character_seed/character_key dari response checkVersion. "
                "Isi manual di config (character_seed & character_key)."
            )

        login_request = SystemLoginRequest.from_credentials(
            self.config.credentials.username,
            self.config.credentials.password,
            character_seed=seed,
            character_key=key,
            loader=self.config.loader,
            library_url=self.config.library_url,
        )
        login = self._call(
            "SystemLogin.loginUser",
            login_request.to_body(),
            SystemLoginResponse.from_content,
        )

        get_characters_request = GetAllCharactersRequest(server_id=self.config.server_id)
        characters = self._call(
            "SystemLogin.getAllCharacters",
            get_characters_request.to_body(login),
            GetAllCharactersResponse.from_content,
        )

        # Pick a character index for getCharacterData
        char_data: GetCharacterDataResponse | None = None
        if characters.characters:
            idx = min(max(self.config.selected_character_index, 0), len(characters.characters) - 1)
            selected = characters.characters[idx]
            char_data = self._call(
                "SystemLogin.getCharacterData",
                [[selected.char_id, login.sessionkey]],
                GetCharacterDataResponse.from_content,
            )
        print(char_data.inventory.skills)

        return WorkflowResult(
            version=version,
            analytics=analytics,
            events=events,
            login=login,
            characters=characters,
            character_data=char_data,
        )


def print_summary(result: WorkflowResult) -> None:
    """Pretty print the workflow result to the console."""

    console = Console()
    console.rule("[bold cyan]SystemLogin.checkVersion[/bold cyan]")
    console.print(result.version)

    console.rule("[bold cyan]Analytics.libraries[/bold cyan]")
    console.print(result.analytics)

    console.rule("[bold cyan]EventsService.get[/bold cyan]")
    console.print(result.events)

    console.rule("[bold cyan]SystemLogin.loginUser[/bold cyan]")
    console.print(result.login)

    console.rule("[bold cyan]SystemLogin.getAllCharacters[/bold cyan]")
    console.print(result.characters)

    if result.character_data is not None:
        console.rule("[bold cyan]SystemLogin.getCharacterData[/bold cyan]")
        console.print(result.character_data)

    if result.character_data is not None:
        console.rule("[bold cyan]SystemLogin.getCharacterData[/bold cyan]")
        console.print(result.character_data)
