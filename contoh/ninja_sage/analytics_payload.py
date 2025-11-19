"""Generate payloads for the Analytics.libraries AMF call."""

from __future__ import annotations

import json
import urllib.request
import zlib
from collections import OrderedDict
from functools import lru_cache
from typing import Dict

DEFAULT_ASSET_BASE_URL = "https://ns-assets.ninjasage.id/static/lib/"

ASSET_NAMES = [
    "skills",
    "library",
    "enemy",
    "npc",
    "pet",
    "mission",
    "gamedata",
    "talents",
    "senjutsu",
    "skill-effect",
    "weapon-effect",
    "back_item-effect",
    "accessory-effect",
    "arena-effect",
    "animation",
]

EXPECTED_ORDER = [
    "weapon-effect",
    "library",
    "animation",
    "pet",
    "back_item-effect",
    "gamedata",
    "accessory-effect",
    "skills",
    "npc",
    "arena-effect",
    "talents",
    "enemy",
    "skill-effect",
    "senjutsu",
    "mission",
]


def _download(url: str) -> bytes:
    with urllib.request.urlopen(url) as resp:
        return resp.read()


@lru_cache(maxsize=2)
def fetch_asset_lengths(base_url: str = DEFAULT_ASSET_BASE_URL) -> Dict[str, int]:
    base = base_url.rstrip("/")
    lengths: Dict[str, int] = {}
    for name in ASSET_NAMES:
        data = _download(f"{base}/{name}.bin")
        lengths[name] = len(data)
    return lengths


def build_analytics_payload(base_url: str = DEFAULT_ASSET_BASE_URL) -> bytes:
    lengths = fetch_asset_lengths(base_url)
    ordered = OrderedDict((key, lengths[key]) for key in EXPECTED_ORDER)
    json_str = json.dumps(ordered, separators=(",", ":")).encode("utf-8")
    return zlib.compress(json_str, level=9)
