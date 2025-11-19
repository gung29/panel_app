"""Service wrapper for the ``EventsService`` AMF API."""

from __future__ import annotations

from dataclasses import dataclass

from ..client import NinjaSageClient
from ..models import EventsServiceGetRequest, EventsServiceGetResponse
from ..response_utils import extract_first_body, normalize_content


@dataclass
class EventsService:
    client: NinjaSageClient

    def get(self) -> EventsServiceGetResponse:
        request = EventsServiceGetRequest()
        envelope = self.client.invoke("EventsService.get", request.to_body())
        content = extract_first_body(envelope)
        normalized = normalize_content(content)
        return EventsServiceGetResponse.from_content(normalized)

