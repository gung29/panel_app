"""Service layer grouping AMF calls by logical area.

This package exposes higher level classes so you can work per-feature,
for example:

* :class:`SystemLoginService` for all calls under ``SystemLogin.*``
* :class:`AnalyticsService` for ``Analytics.libraries``
* :class:`EventsService` for ``EventsService.get``

Each service uses :class:`ninja_sage.client.NinjaSageClient` under the
hood and returns the dataclasses from :mod:`ninja_sage.models`.
"""

from .analytics import AnalyticsService
from .events import EventsService
from .system_login import SystemLoginService

__all__ = [
    "AnalyticsService",
    "EventsService",
    "SystemLoginService",
]

