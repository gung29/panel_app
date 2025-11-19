"""Helpers for encoding and decoding AMF payloads via Py3AMF."""

from __future__ import annotations

from pathlib import Path
from typing import Any, List, Sequence

try:
    from pyamf import remoting
except ImportError as exc:  # pragma: no cover - dependency hint
    raise ImportError(
        "Py3AMF (module 'pyamf') belum terpasang. Jalankan 'pip install -r requirements.txt' "
        "atau lihat README untuk instruksi instalasi."
    ) from exc


def build_envelope(
    target: str,
    *,
    body: Sequence[Any] | None = None,
    response_path: str = "/1",
    amf_version: int = 3,
) -> remoting.Envelope:
    """Return an AMF envelope containing a single request."""

    envelope = remoting.Envelope(amfVersion=amf_version)
    request = remoting.Request(target=target, body=list(body or []))
    envelope[response_path] = request
    return envelope


def encode_envelope(envelope: remoting.Envelope) -> bytes:
    """Serialize an envelope to bytes suitable for HTTP transmission."""

    return remoting.encode(envelope).getvalue()


def decode_amf_bytes(data: bytes) -> remoting.Envelope:
    """Turn raw AMF bytes into an envelope."""

    return remoting.decode(data)


def load_amf_from_file(path: str | Path) -> remoting.Envelope:
    """Convenience wrapper to decode AMF files exported by Charles Proxy."""

    return decode_amf_bytes(Path(path).expanduser().read_bytes())


def iter_envelope(envelope: remoting.Envelope):
    """Yield ``(response_path, message)`` tuples regardless of Py3AMF version."""

    iterator = envelope.iteritems() if hasattr(envelope, "iteritems") else envelope.items()
    for response_path, message in iterator:
        yield response_path, message


def envelope_summary(envelope: remoting.Envelope) -> List[dict[str, Any]]:
    """Return a simplified list of request/response metadata for logging."""

    details: List[dict[str, Any]] = []
    for response_path, message in iter_envelope(envelope):
        details.append(
            {
                "response_path": response_path,
                "target": getattr(message, "target", None),
                "body": getattr(message, "body", None),
            }
        )
    return details
