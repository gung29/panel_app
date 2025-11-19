"""Models specific to the SystemLogin service.

This module contains request/response types and helpers for:

* ``SystemLogin.loginUser``
* login banners & events
* helper structures shared by higher level flows
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, List, Mapping, Sequence

from .login_payload import DEFAULT_LIBRARY_URL, LoaderInfo, build_login_components


@dataclass(slots=True)
class SystemLoginRequest:
    """Represents the ``SystemLogin.loginUser`` call."""

    username: str
    encrypted_password: str  # String
    character_seed: int  # sent as AMF Number
    bytes_loaded: int  # Integer
    bytes_total: int  # Integer
    character_key: str
    specific_item: str
    random_seed: str
    password_length: int  # Integer

    @classmethod
    def from_credentials(
        cls,
        username: str,
        password: str,
        *,
        character_seed: int,
        character_key: str,
        loader: LoaderInfo | None = None,
        library_url: str = DEFAULT_LIBRARY_URL,
    ) -> "SystemLoginRequest":
        if character_seed is None or character_key is None:
            raise ValueError("character_seed dan character_key wajib tersedia dari checkVersion")
        components = build_login_components(
            username,
            password,
            character_seed,
            character_key,
            loader=loader,
            library_url=library_url,
        )
        return cls(
            username=components["username"],
            encrypted_password=components["encrypted_password"],
            character_seed=components["character_seed"],
            bytes_loaded=components["bytes_loaded"],
            bytes_total=components["bytes_total"],
            character_key=components["character_key"],
            specific_item=components["specific_item"],
            random_seed=components["random_seed"],
            password_length=components["password_length"],
        )

    def to_body(self) -> List[Any]:
        # Match the in‑game AMF types:
        # [0] String username
        # [1] String encrypted_password
        # [2] Number character_seed
        # [3] Integer bytes_loaded
        # [4] Integer bytes_total
        # [5] String character_key
        # [6] String specific_item
        # [7] String random_seed
        # [8] Integer password_length
        params: List[Any] = [
            self.username,
            self.encrypted_password,
            float(self.character_seed),
            int(self.bytes_loaded),
            int(self.bytes_total),
            self.character_key,
            self.specific_item,
            self.random_seed,
            int(self.password_length),
        ]
        # Flash client wraps the parameter list in an outer array.
        return [params]


@dataclass(slots=True)
class LoginBanner:
    url: str | None
    menu: str | None
    title: str | None
    action: str | None
    raw: Mapping[str, Any]

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any]) -> "LoginBanner":
        return cls(
            url=payload.get("url"),
            menu=payload.get("menu"),
            title=payload.get("title"),
            action=payload.get("action"),
            raw=payload,
        )


def _flatten_banner_payload(value: Any) -> List[Mapping[str, Any]]:
    results: List[Mapping[str, Any]] = []

    def _walk(node: Any) -> None:
        if isinstance(node, Mapping):
            results.append(node)
        elif isinstance(node, Sequence) and not isinstance(node, (str, bytes, bytearray)):
            for child in node:
                _walk(child)

    _walk(value)
    return results


def _parse_login_events(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, Mapping):
        # Unexpected shape; fall back to any string values.
        return [str(v) for v in value.values() if isinstance(v, str)]
    events: List[str] = []
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes, bytearray)):
        for item in value:
            if isinstance(item, str):
                events.append(item)
    return events


@dataclass(slots=True)
class SystemLoginResponse:
    status: int
    error: int
    uid: int
    sessionkey: str
    hash: str
    system_time: str | None = None
    banners: List[LoginBanner] = field(default_factory=list)
    events: List[str] = field(default_factory=list)
    clan_season: str | None = None
    crew_season: str | None = None
    client_token: str | None = None

    @classmethod
    def from_content(cls, content: Mapping[str, Any]) -> "SystemLoginResponse":
        banners_raw = content.get("banners", [])
        banner_objects = [LoginBanner.from_mapping(p) for p in _flatten_banner_payload(banners_raw)]

        return cls(
            status=content.get("status", 0),
            error=content.get("error", 0),
            uid=content.get("uid"),
            sessionkey=content.get("sessionkey"),
            hash=content.get("hash"),
            system_time=content.get("system_time"),
            banners=banner_objects,
            events=_parse_login_events(content.get("events")),
            clan_season=content.get("clan_season"),
            crew_season=content.get("crew_season"),
            client_token=content.get("__"),
        )


__all__ = [
    "SystemLoginRequest",
    "SystemLoginResponse",
    "LoginBanner",
]

