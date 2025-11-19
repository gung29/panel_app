"""Common request/response models shared across services.

This module contains small, generic pieces that are reused by multiple
service layers, such as version checking, analytics and events.
"""

from __future__ import annotations

import binascii
from dataclasses import dataclass, field
from typing import Any, List, Mapping, Sequence

try:
    from pyamf.amf3 import ByteArray
except ImportError as exc:  # pragma: no cover - dependency hint
    raise ImportError(
        "Py3AMF (module 'pyamf') belum terpasang. Jalankan 'pip install -r requirements.txt' "
        "atau lihat README untuk instruksi instalasi."
    ) from exc

from .analytics_payload import build_analytics_payload


# ---------------------------------------------------------------------------
# Requests
# ---------------------------------------------------------------------------


@dataclass(slots=True)
class CheckVersionRequest:
    """Represents the ``SystemLogin.checkVersion`` call."""

    channel: str = "Public 0.52"

    def to_body(self) -> List[Any]:
        # Game client wraps the channel value in an extra array.
        return [[self.channel]]


@dataclass(slots=True)
class AnalyticsLibrariesRequest:
    """Represents the ``Analytics.libraries`` call."""

    payload: bytes

    @classmethod
    def from_hex(cls, payload_hex: str) -> "AnalyticsLibrariesRequest":
        cleaned = "".join(payload_hex.split())
        try:
            data = binascii.unhexlify(cleaned)
        except binascii.Error as exc:  # pragma: no cover - invalid hex
            raise ValueError(f"payload_hex tidak valid: {exc}") from exc
        return cls(payload=data)

    @classmethod
    def from_assets(cls, base_url: str) -> "AnalyticsLibrariesRequest":
        return cls(payload=build_analytics_payload(base_url))

    def to_body(self) -> List[Any]:
        return [[ByteArray(self.payload)]]


@dataclass(slots=True)
class EventsServiceGetRequest:
    """Represents the ``EventsService.get`` call."""

    def to_body(self) -> List[Any]:
        return [None]


# ---------------------------------------------------------------------------
# Responses
# ---------------------------------------------------------------------------


@dataclass(slots=True)
class CheckVersionResponse:
    status: int
    error: int
    cdn: str | None = None
    character_seed: int | None = None
    character_key: str | None = None
    remote_enabled: bool | None = None

    @classmethod
    def from_content(cls, content: Mapping[str, Any]) -> "CheckVersionResponse":
        return cls(
            status=content.get("status", 0),
            error=content.get("error", 0),
            cdn=content.get("cdn"),
            character_seed=content.get("_"),
            character_key=content.get("__"),
            remote_enabled=content.get("_rm"),
        )


@dataclass(slots=True)
class AnalyticsLibrariesResponse:
    status: int
    error: int

    @classmethod
    def from_content(cls, content: Mapping[str, Any]) -> "AnalyticsLibrariesResponse":
        return cls(status=content.get("status", 0), error=content.get("error", 0))


@dataclass(slots=True)
class EventCollections:
    seasonal: List[Any] = field(default_factory=list)
    permanent: List[Any] = field(default_factory=list)
    features: List[Any] = field(default_factory=list)
    packages: List[Any] | None = None

    @classmethod
    def from_content(cls, content: Any | None) -> "EventCollections":
        if not content:
            return cls()

        if isinstance(content, Sequence) and not isinstance(content, (str, bytes, bytearray)):
            if not content:
                return cls()
            first = content[0]
            if isinstance(first, Mapping):
                content = first
            else:
                return cls()

        if not isinstance(content, Mapping):
            return cls()

        return cls(
            seasonal=list(content.get("seasonal", [])),
            permanent=list(content.get("event:permanent", [])),
            features=list(content.get("features", [])),
            packages=content.get("packages"),
        )


@dataclass(slots=True)
class EventsServiceGetResponse:
    status: int
    error: int
    events: EventCollections

    @classmethod
    def from_content(cls, content: Mapping[str, Any]) -> "EventsServiceGetResponse":
        return cls(
            status=content.get("status", 0),
            error=content.get("error", 0),
            events=EventCollections.from_content(content.get("events")),
        )


__all__ = [
    "CheckVersionRequest",
    "CheckVersionResponse",
    "AnalyticsLibrariesRequest",
    "AnalyticsLibrariesResponse",
    "EventsServiceGetRequest",
    "EventCollections",
    "EventsServiceGetResponse",
]

