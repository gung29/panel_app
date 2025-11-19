"""Client helpers for replaying Ninja Sage AMF requests."""

from .amf_utils import decode_amf_bytes, encode_envelope, iter_envelope, load_amf_from_file
from .client import NinjaSageClient
from .models import (
    AnalyticsLibrariesRequest,
    AnalyticsLibrariesResponse,
    CheckVersionRequest,
    CheckVersionResponse,
    EventCollections,
    EventsServiceGetRequest,
    EventsServiceGetResponse,
    GetAllCharactersRequest,
    GetAllCharactersResponse,
    SystemLoginRequest,
    SystemLoginResponse,
    WorkflowResult,
    CharacterCoreData,
    CharacterInventory,
    CharacterPoints,
    CharacterSets,
    CharacterSlots,
    GetCharacterDataResponse,
)
from .services import AnalyticsService, EventsService, SystemLoginService
from .workflow import Credentials, NinjaSageWorkflow, WorkflowConfig, print_summary

__all__ = [
    "NinjaSageClient",
    "decode_amf_bytes",
    "encode_envelope",
    "iter_envelope",
    "load_amf_from_file",
    "AnalyticsLibrariesRequest",
    "AnalyticsLibrariesResponse",
    "CheckVersionRequest",
    "CheckVersionResponse",
    "EventCollections",
    "EventsServiceGetRequest",
    "EventsServiceGetResponse",
    "GetAllCharactersRequest",
    "GetAllCharactersResponse",
    "SystemLoginRequest",
    "SystemLoginResponse",
    "WorkflowResult",
    # Service layer
    "AnalyticsService",
    "EventsService",
    "SystemLoginService",
    "Credentials",
    "NinjaSageWorkflow",
    "WorkflowConfig",
    "print_summary",
]
