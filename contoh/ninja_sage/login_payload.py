"""Helpers to rebuild SystemLogin.loginUser payloads from username/password."""

from __future__ import annotations

import base64
import hashlib
import json
import random
import time
import urllib.request
import zlib
from dataclasses import dataclass
from functools import lru_cache
from typing import Dict

from Crypto.Cipher import AES
from Crypto.Util.Padding import pad

DEFAULT_LIBRARY_URL = "https://ns-assets.ninjasage.id/static/lib/library.bin"


@dataclass(slots=True)
class LoaderInfo:
    """Mimics ``loaderInfo`` from the Flash client."""

    bytes_loaded: int = 8_216_461
    bytes_total: int = 8_216_461


class _Crypt:
    @staticmethod
    def _make_iv(seed: str) -> bytes:
        iv = seed.encode("latin1")
        block_size = 16
        pad_len = block_size - (len(iv) % block_size)
        padded = iv + bytes([pad_len]) * pad_len
        return padded[:block_size]

    @classmethod
    def encrypt(cls, plaintext: str, key: str, seed: int) -> str:
        aes_key = key.encode("latin1")
        iv = cls._make_iv(str(seed))
        data = pad(plaintext.encode("latin1"), 16)
        cipher = AES.new(aes_key, AES.MODE_CBC, iv)
        ciphertext = cipher.encrypt(data)
        return base64.b64encode(ciphertext).decode("ascii")


class _PM_PRNG:
    MOD = 2_147_483_647
    MUL = 16_807

    def __init__(self, seed: int) -> None:
        if seed == 0:
            t = int(time.time() * 1000)
            r = int(random.random() * 0.025 * 0x7FFFFFFF)
            seed = (t ^ r) & 0x7FFFFFFF
        self.seed = seed & 0x7FFFFFFF

    def next_int(self) -> int:
        self.seed = (self.seed * self.MUL) % self.MOD
        return self.seed


@lru_cache(maxsize=2)
def load_library_levels(library_url: str = DEFAULT_LIBRARY_URL) -> Dict[str, int]:
    with urllib.request.urlopen(library_url) as resp:
        compressed = resp.read()
    data = zlib.decompress(compressed)
    items = json.loads(data.decode("utf-8"))
    levels: Dict[str, int] = {}
    for entry in items:
        item_id = entry.get("id")
        if item_id is None:
            continue
        levels[item_id] = int(entry.get("level", 0))
    return levels


def _cucsg_hash(value: str) -> str:
    payload = bytes((ord(ch) & 0xFF) for ch in value)
    return hashlib.sha256(payload).hexdigest()


def _safe_mod(a: int, b: int) -> int:
    return 0 if b == 0 else a % b


def get_specific_item(loader: LoaderInfo, character_seed: int | float, levels: Dict[str, int]) -> str:
    bytes_total = int(loader.bytes_total)
    bytes_loaded = int(loader.bytes_loaded)
    character_seed = int(character_seed)
    lvl_hair_1 = levels.get("hair_10000_1", 0)
    lvl_hair_0 = levels.get("hair_10000_0", 0)
    lvl_acc_2003 = levels.get("accessory_2003", 0)

    loc4_num = (
        (bytes_total ^ bytes_loaded)
        + 1337
        ^ character_seed
        ^ 1337
        + 1337
        ^ character_seed
        ^ 1337
        + 1337
        ^ 0x0539
        & _safe_mod(_safe_mod(bytes_loaded, lvl_hair_1), bytes_loaded)
        & bytes_total
        ^ _safe_mod(_safe_mod(lvl_hair_0, character_seed), 1_333_777)
        + lvl_acc_2003
    )

    loc4_str = str(loc4_num)
    hashed = _cucsg_hash(loc4_str)
    seed_str = str(character_seed)
    return seed_str + hashed + seed_str * 4


def get_random_n_seed(character_seed: int | float, loader: LoaderInfo) -> str:
    character_seed = int(character_seed)
    seed_rng = character_seed % int(loader.bytes_loaded)
    rng = _PM_PRNG(seed_rng)
    return "".join(str(rng.next_int()) for _ in range(4))


def build_login_components(
    username: str,
    password: str,
    character_seed: int | float,
    character_key: str,
    *,
    loader: LoaderInfo | None = None,
    library_url: str = DEFAULT_LIBRARY_URL,
) -> Dict[str, object]:
    loader = loader or LoaderInfo()
    character_seed = int(character_seed)
    levels = load_library_levels(library_url)
    encrypted_password = _Crypt.encrypt(password, character_key, character_seed)
    specific_item = get_specific_item(loader, character_seed, levels)
    random_seed = get_random_n_seed(character_seed, loader)

    return {
        "username": username,
        "encrypted_password": encrypted_password,
        "character_seed": character_seed,
        "bytes_loaded": loader.bytes_loaded,
        "bytes_total": loader.bytes_total,
        "character_key": character_key,
        "specific_item": specific_item,
        "random_seed": random_seed,
        "password_length": len(password),
    }
