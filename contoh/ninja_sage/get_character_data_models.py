"""Models for the ``SystemLogin.getCharacterData`` response."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, List, Mapping


@dataclass(slots=True)
class CharacterPoints:
    attrib_wind: int = 0
    attrib_fire: int = 0
    attrib_lightning: int = 0
    attrib_water: int = 0
    attrib_earth: int = 0
    attrib_free: int = 0

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any] | None) -> "CharacterPoints":
        if not payload:
            return cls()
        return cls(
            attrib_wind=payload.get("atrrib_wind", 0),
            attrib_fire=payload.get("atrrib_fire", 0),
            attrib_lightning=payload.get("atrrib_lightning", 0),
            attrib_water=payload.get("atrrib_water", 0),
            attrib_earth=payload.get("atrrib_earth", 0),
            attrib_free=payload.get("atrrib_free", 0),
        )


@dataclass(slots=True)
class CharacterSlots:
    weapons: int = 0
    back_items: int = 0
    accessories: int = 0
    hairstyles: int = 0
    clothing: int = 0

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any] | None) -> "CharacterSlots":
        if not payload:
            return cls()
        return cls(
            weapons=payload.get("weapons", 0),
            back_items=payload.get("back_items", 0),
            accessories=payload.get("accessories", 0),
            hairstyles=payload.get("hairstyles", 0),
            clothing=payload.get("clothing", 0),
        )


@dataclass(slots=True)
class CharacterCoreData:
    character_id: int
    name: str
    level: int
    xp: int
    gender: int
    rank: int
    merit: int
    prestige: int
    element_1: int
    element_2: int | None
    element_3: int | None
    talent_1: Any
    talent_2: Any
    talent_3: Any
    gold: int
    tp: int
    ss: int
    char_class: Any
    senjutsu: Any
    pvp_points: int

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any] | None) -> "CharacterCoreData":
        payload = payload or {}
        return cls(
            character_id=payload.get("character_id"),
            name=payload.get("character_name"),
            level=payload.get("character_level", 0),
            xp=payload.get("character_xp", 0),
            gender=payload.get("character_gender", 0),
            rank=payload.get("character_rank", 0),
            merit=payload.get("character_merit", 0),
            prestige=payload.get("character_prestige", 0),
            element_1=payload.get("character_element_1", 0),
            element_2=payload.get("character_element_2"),
            element_3=payload.get("character_element_3"),
            talent_1=payload.get("character_talent_1"),
            talent_2=payload.get("character_talent_2"),
            talent_3=payload.get("character_talent_3"),
            gold=payload.get("character_gold", 0),
            tp=payload.get("character_tp", 0),
            ss=payload.get("character_ss", 0),
            char_class=payload.get("character_class"),
            senjutsu=payload.get("character_senjutsu"),
            pvp_points=payload.get("character_pvp_points", 0),
        )


@dataclass(slots=True)
class CharacterSets:
    weapon: str | None = None
    back_item: str | None = None
    accessory: str | None = None
    hairstyle: str | None = None
    clothing: str | None = None
    skills: str | None = None
    senjutsu_skills: Any = None
    hair_color: str | None = None
    skin_color: str | None = None
    face: str | None = None

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any] | None) -> "CharacterSets":
        payload = payload or {}
        return cls(
            weapon=payload.get("weapon"),
            back_item=payload.get("back_item"),
            accessory=payload.get("accessory"),
            hairstyle=payload.get("hairstyle"),
            clothing=payload.get("clothing"),
            skills=payload.get("skills"),
            senjutsu_skills=payload.get("senjutsu_skills"),
            hair_color=payload.get("hair_color"),
            skin_color=payload.get("skin_color"),
            face=payload.get("face"),
        )


@dataclass(slots=True)
class CharacterInventory:
    weapons: str | None = None
    back_items: str | None = None
    accessories: str | None = None
    sets: str | None = None
    hairs: str | None = None
    skills: str | None = None
    talent_skills: str | None = None
    senjutsu_skills: str | None = None
    materials: str | None = None
    essentials: str | None = None
    consumables: str | None = None
    animations: str | None = None

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any] | None) -> "CharacterInventory":
        payload = payload or {}
        return cls(
            weapons=payload.get("char_weapons"),
            back_items=payload.get("char_back_items"),
            accessories=payload.get("char_accessories"),
            sets=payload.get("char_sets"),
            hairs=payload.get("char_hairs"),
            skills=payload.get("char_skills"),
            talent_skills=payload.get("char_talent_skills"),
            senjutsu_skills=payload.get("char_senjutsu_skills"),
            materials=payload.get("char_materials"),
            essentials=payload.get("char_essentials"),
            consumables=payload.get("char_items"),
            animations=payload.get("char_animations"),
        )


@dataclass(slots=True)
class ClanInfo:
    id: int | None = None
    name: str | None = None
    banner: str | None = None

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any] | None) -> "ClanInfo":
        if not payload:
            return cls()
        return cls(
            id=payload.get("id"),
            name=payload.get("name"),
            banner=payload.get("banner"),
        )


@dataclass(slots=True)
class GetCharacterDataResponse:
    status: int
    error: int
    announcements: str | None
    account_type: int
    emblem_duration: int
    has_unread_mails: bool
    features: List[str] = field(default_factory=list)
    events: Any | None = None
    character: CharacterCoreData | None = None
    points: CharacterPoints = field(default_factory=CharacterPoints)
    slots: CharacterSlots = field(default_factory=CharacterSlots)
    sets: CharacterSets = field(default_factory=CharacterSets)
    inventory: CharacterInventory = field(default_factory=CharacterInventory)
    recruiters: List[Any] = field(default_factory=list)
    recruit_data: List[Any] = field(default_factory=list)
    pet_data: Any | None = None
    clan: ClanInfo = field(default_factory=ClanInfo)
    raw: Mapping[str, Any] | None = None

    @classmethod
    def from_content(cls, content: Mapping[str, Any]) -> "GetCharacterDataResponse":
        return cls(
            status=content.get("status", 0),
            error=content.get("error", 0),
            announcements=content.get("announcements"),
            account_type=content.get("account_type", 0),
            emblem_duration=content.get("emblem_duration", 0),
            has_unread_mails=content.get("has_unread_mails", False),
            features=list(content.get("features", [])),
            events=content.get("events"),
            character=CharacterCoreData.from_mapping(content.get("character_data")),
            points=CharacterPoints.from_mapping(content.get("character_points")),
            slots=CharacterSlots.from_mapping(content.get("character_slots")),
            sets=CharacterSets.from_mapping(content.get("character_sets")),
            inventory=CharacterInventory.from_mapping(content.get("character_inventory")),
            recruiters=list(content.get("recruiters", [])),
            recruit_data=list(content.get("recruit_data", [])),
            pet_data=content.get("pet_data"),
            clan=ClanInfo.from_mapping(content.get("clan")),
            raw=content,
        )
