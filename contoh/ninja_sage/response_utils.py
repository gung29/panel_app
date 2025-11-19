"""Helpers for turning AMF envelopes into plain Python mappings.

This module centralises the logic for extracting the first response body
from an AMF envelope and normalising it into a mapping. It is used by
both the high level workflow and the per-service clients.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from typing import Any

from .amf_utils import iter_envelope


def extract_first_body(envelope) -> Any:
    """Return the raw ``body`` of the first AMF response in *envelope*.

    If the envelope is empty this returns ``None``.
    """

    for _, message in iter_envelope(envelope):
        return getattr(message, "body", None)
    return None


def normalize_content(content: Any) -> Mapping[str, Any]:
    """Convert arbitrary AMF payload objects into a plain mapping.

    - If *content* is already a mapping, it is returned as-is.
    - If it's a Py3AMF object, ``__dict__`` is used and the nested
      ``body`` mapping (if present) is merged on top.
    - If it's a bare list/tuple, the first element is treated as a
      status code and wrapped into ``{"status": value}``.
    - Any other scalar is wrapped into ``{"status": value}``.
    """

    if content is None:
        return {}

    if isinstance(content, Mapping):
        return content

    if hasattr(content, "__dict__"):
        data = {
            key: value
            for key, value in vars(content).items()
            if not callable(value)
        }
        body = data.get("body")
        if isinstance(body, Mapping):
            merged = {**body, **{k: v for k, v in data.items() if k != "body"}}
            return merged
        return data

    if isinstance(content, Sequence) and not isinstance(content, (str, bytes, bytearray)):
        return {"status": content[0] if content else None}

    return {"status": content}

