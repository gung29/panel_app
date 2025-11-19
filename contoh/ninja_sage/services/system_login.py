"""Service wrapper for the ``SystemLogin`` AMF API.

This module groups all calls related to login & characters so you can
work on them in isolation without touching the global workflow.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from ..client import NinjaSageClient
from ..login_payload import DEFAULT_LIBRARY_URL, LoaderInfo
from ..models import (
    CheckVersionRequest,
    CheckVersionResponse,
    GetAllCharactersRequest,
    GetAllCharactersResponse,
    SystemLoginRequest,
    SystemLoginResponse,
    GetCharacterDataResponse,
)
from ..response_utils import extract_first_body, normalize_content


@dataclass
class SystemLoginService:
    client: NinjaSageClient
    loader: LoaderInfo = field(default_factory=LoaderInfo)
    library_url: str = DEFAULT_LIBRARY_URL

    def _call(self, target: str, body: list[Any], parser):
        envelope = self.client.invoke(target, body=body)
        content = extract_first_body(envelope)
        normalized = normalize_content(content)
        return parser(normalized)

    # ------------------------------------------------------------------
    # Low-level calls
    # ------------------------------------------------------------------

    def check_version(self, channel: str = "Public 0.52") -> CheckVersionResponse:
        request = CheckVersionRequest(channel=channel)
        return self._call(
            "SystemLogin.checkVersion",
            request.to_body(),
            CheckVersionResponse.from_content,
        )

    def login_user(
        self,
        username: str,
        password: str,
        *,
        character_seed: float | int,
        character_key: str,
    ) -> SystemLoginResponse:
        request = SystemLoginRequest.from_credentials(
            username,
            password,
            character_seed=character_seed,
            character_key=character_key,
            loader=self.loader,
            library_url=self.library_url,
        )
        return self._call(
            "SystemLogin.loginUser",
            request.to_body(),
            SystemLoginResponse.from_content,
        )

    def get_all_characters(
        self,
        login_response: SystemLoginResponse,
        *,
        server_id: int,
    ) -> GetAllCharactersResponse:
        request = GetAllCharactersRequest(server_id=server_id)
        return self._call(
            "SystemLogin.getAllCharacters",
            request.to_body(login_response),
            GetAllCharactersResponse.from_content,
        )

    def get_character_data(
        self,
        char_id: int,
        sessionkey: str,
    ) -> GetCharacterDataResponse:
        from ..models import SystemLoginResponse as _SLR  # type: ignore

        # Reuse the same pattern as the Flash client: single array argument.
        body = [[int(char_id), str(sessionkey)]]
        envelope = self.client.invoke("SystemLogin.getCharacterData", body=body)
        content = extract_first_body(envelope)
        normalized = normalize_content(content)
        return GetCharacterDataResponse.from_content(normalized)
