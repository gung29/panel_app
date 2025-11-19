"""HTTP client able to replay Ninja Sage AMF calls."""

from __future__ import annotations

from typing import Any, Mapping, Sequence

import requests

try:
    from pyamf import remoting
except ImportError as exc:  # pragma: no cover - dependency hint
    raise ImportError(
        "Py3AMF (module 'pyamf') belum terpasang. Jalankan 'pip install -r requirements.txt' "
        "atau lihat README untuk instruksi instalasi."
    ) from exc

from urllib.parse import urlparse

from .amf_utils import build_envelope, decode_amf_bytes, encode_envelope, envelope_summary
from .constants import DEFAULT_BASE_URL, DEFAULT_ENDPOINT_PATH, DEFAULT_HEADERS


class NinjaSageClient:
    """Thin wrapper around the Ninja Sage AMF endpoints."""

    def __init__(
        self,
        base_url: str = DEFAULT_BASE_URL,
        *,
        session: requests.Session | None = None,
        default_headers: Mapping[str, str] | None = None,
        endpoint_path: str = DEFAULT_ENDPOINT_PATH,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.endpoint_path = endpoint_path if endpoint_path.startswith("/") else f"/{endpoint_path}"
        self.session = session or requests.Session()
        self.session.verify = False
        headers = dict(DEFAULT_HEADERS)
        if default_headers:
            headers.update(default_headers)
        self.session.headers.update(headers)

        parsed = urlparse(self.base_url)
        if parsed.netloc:
            self.session.headers.setdefault("Host", parsed.netloc)

    # Public API -----------------------------------------------------------
    def invoke(
        self,
        target: str,
        body: Sequence[Any] | None = None,
        *,
        response_path: str = "/1",
        amf_version: int = 3,
        extra_headers: Mapping[str, str] | None = None,
        timeout: int | float = 20,
    ) -> remoting.Envelope:
        """Encode and send a single AMF request."""

        envelope = build_envelope(
            target,
            body=body,
            response_path=response_path,
            amf_version=amf_version,
        )
        return self.send_envelope(envelope, timeout=timeout, extra_headers=extra_headers)

    def send_envelope(
        self,
        envelope: remoting.Envelope,
        *,
        extra_headers: Mapping[str, str] | None = None,
        timeout: int | float = 20,
    ) -> remoting.Envelope:
        """Send a fully composed envelope to the server."""

        payload = encode_envelope(envelope)
        url = self._build_url()
        headers = dict(self.session.headers)
        if extra_headers:
            headers.update(extra_headers)
        response = self.session.post(url, data=payload, headers=headers, timeout=timeout)
        response.raise_for_status()
        return decode_amf_bytes(response.content)

    def decode_local_file(self, path: str) -> remoting.Envelope:
        """Quick helper mirroring the workflow in Charles Proxy."""

        with open(path, "rb") as handle:
            return decode_amf_bytes(handle.read())

    def describe(self, envelope: remoting.Envelope) -> str:
        """Return a short human readable summary of a decoded envelope."""

        parts = envelope_summary(envelope)
        lines = []
        for index, entry in enumerate(parts, start=1):
            lines.append(
                f"#{index} response={entry['response_path']} target={entry['target']}\n" f"    body={entry['body']}"
            )
        return "\n".join(lines)

    # Internal -------------------------------------------------------------
    def _build_url(self) -> str:
        return f"{self.base_url}{self.endpoint_path}"
