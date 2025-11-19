"""High level result models used by the workflow orchestrator."""

from __future__ import annotations

from dataclasses import dataclass

from .models_characters import GetAllCharactersResponse
from .models_common import (
    AnalyticsLibrariesResponse,
    CheckVersionResponse,
    EventsServiceGetResponse,
)
from .models_system_login import SystemLoginResponse
from .get_character_data_models import GetCharacterDataResponse


@dataclass(slots=True)
class WorkflowResult:
    version: CheckVersionResponse
    analytics: AnalyticsLibrariesResponse
    events: EventsServiceGetResponse
    login: SystemLoginResponse
    characters: GetAllCharactersResponse
    character_data: GetCharacterDataResponse | None = None


__all__ = ["WorkflowResult"]

