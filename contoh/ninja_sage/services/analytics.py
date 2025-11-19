"""Service wrapper for the ``Analytics`` AMF API."""

from __future__ import annotations

from dataclasses import dataclass

from ..analytics_payload import DEFAULT_ASSET_BASE_URL
from ..client import NinjaSageClient
from ..models import AnalyticsLibrariesRequest, AnalyticsLibrariesResponse
from ..response_utils import extract_first_body, normalize_content


@dataclass
class AnalyticsService:
    client: NinjaSageClient
    base_url: str = DEFAULT_ASSET_BASE_URL

    def libraries(self) -> AnalyticsLibrariesResponse:
        request = AnalyticsLibrariesRequest.from_assets(self.base_url)
        envelope = self.client.invoke("Analytics.libraries", request.to_body())
        content = extract_first_body(envelope)
        normalized = normalize_content(content)
        return AnalyticsLibrariesResponse.from_content(normalized)

