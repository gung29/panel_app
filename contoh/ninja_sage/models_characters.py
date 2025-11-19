"""Models for character lists and selection (getAllCharacters)."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Iterable, List, Mapping


@dataclass(slots=True)
class CharacterSummary:
    char_id: int
    acc_id: int
    name: str
    level: int
    xp: int
    gender: int
    rank: int
    prestige: int
    element_1: int | None
    element_2: int | None
    element_3: int | None
    talent_1: int | None
    talent_2: int | None
    talent_3: int | None
    gold: int
    tp: int
    raw: Mapping[str, Any]

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any]) -> "CharacterSummary":
        return cls(
            char_id=payload.get("char_id") or payload.get("character_id") or payload.get("cid"),
            acc_id=payload.get("acc_id") or payload.get("account_id") or 0,
            name=payload.get("character_name") or payload.get("name"),
            level=payload.get("character_level") or payload.get("level") or 0,
            xp=payload.get("character_xp") or payload.get("xp") or 0,
            gender=payload.get("character_gender") or payload.get("gender") or 0,
            rank=payload.get("character_rank") or payload.get("rank") or 0,
            prestige=payload.get("character_prestige") or payload.get("prestige") or 0,
            element_1=payload.get("character_element_1"),
            element_2=payload.get("character_element_2"),
            element_3=payload.get("character_element_3"),
            talent_1=payload.get("character_talent_1"),
            talent_2=payload.get("character_talent_2"),
            talent_3=payload.get("character_talent_3"),
            gold=payload.get("character_gold") or 0,
            tp=payload.get("character_tp") or 0,
            raw=payload,
        )


@dataclass(slots=True)
class GetAllCharactersRequest:
    """Represents the ``SystemLogin.getAllCharacters`` call."""

    server_id: int = 12  # kept for future use / routing

    def to_body(self, login_response: "SystemLoginResponse") -> List[Any]:  # type: ignore[name-defined]
        # The Flash client calls:
        #   service("SystemLogin.getAllCharacters", [account_id, sessionkey], ...)
        params = [
            int(login_response.uid),
            str(login_response.sessionkey),
        ]
        return [params]


@dataclass(slots=True)
class GetAllCharactersResponse:
    status: int
    error: int
    account_type: int
    emblem_duration: int
    tokens: int
    total_characters: int
    characters: List[CharacterSummary] = field(default_factory=list)

    @classmethod
    def from_content(cls, content: Mapping[str, Any]) -> "GetAllCharactersResponse":
        account_data: Iterable[Mapping[str, Any]] = content.get("account_data", [])
        characters = [CharacterSummary.from_mapping(entry) for entry in account_data]
        return cls(
            status=content.get("status", 0),
            error=content.get("error", 0),
            account_type=content.get("account_type", 0),
            emblem_duration=content.get("emblem_duration", 0),
            tokens=content.get("tokens", 0),
            total_characters=content.get("total_characters", len(characters)),
            characters=characters,
        )


__all__ = [
    "CharacterSummary",
    "GetAllCharactersRequest",
    "GetAllCharactersResponse",
]

