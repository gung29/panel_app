"""HTTP API sederhana yang membungkus workflow Ninja Sage AMF.

Server ini:
- Membaca konfigurasi dari ``config.json`` (lihat README di folder ``contoh``)
- Menjalankan urutan AMF penuh via :class:`NinjaSageWorkflow`
- Mengembalikan hasilnya sebagai JSON untuk dikonsumsi frontend (Flutter)

Endpoint utama:
- POST /api/workflow
    Body JSON: {"username": "...", "password": "..."} (opsional; jika kosong
    akan memakai kredensial dari config.json)
    Response JSON: {
      "version": {...},
      "analytics": {...},
      "events": {...},
      "login": {...},
      "characters": {...},
      "character_data": {...} | null
    }

Selain itu, ada endpoint ringkas:
- GET /api/characters
    Menjalankan workflow dengan kredensial dari config.json dan hanya
    mengembalikan blok "characters" (GetAllCharactersResponse).
"""

from __future__ import annotations

import json
from dataclasses import asdict
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any

from ninja_sage import NinjaSageClient, NinjaSageWorkflow, WorkflowConfig


CONFIG_PATH = "config.json"


def _build_workflow(config_override: dict[str, Any] | None = None) -> NinjaSageWorkflow:
  """Bangun objek workflow dari file config + override opsional."""

  base_config = WorkflowConfig.from_file(CONFIG_PATH)
  if not config_override:
    cfg = base_config
  else:
    payload = {
      "base_url": config_override.get("base_url", base_config.base_url),
      "channel": config_override.get("channel", base_config.channel),
      "include_events": config_override.get("include_events", base_config.include_events),
      "analytics_base_url": config_override.get("analytics_base_url", base_config.analytics_base_url),
      "library_url": config_override.get("library_url", base_config.library_url),
      "loader_info": {
        "bytes_loaded": base_config.loader.bytes_loaded,
        "bytes_total": base_config.loader.bytes_total,
      },
      "server_id": config_override.get("server_id", base_config.server_id),
      "selected_character_index": config_override.get(
        "selected_character_index", base_config.selected_character_index
      ),
      "character_seed": config_override.get("character_seed", base_config.character_seed),
      "character_key": config_override.get("character_key", base_config.character_key),
      "credentials": config_override.get(
        "credentials",
        {
          "username": getattr(base_config, "credentials").username,
          "password": getattr(base_config, "credentials").password,
        },
      ),
    }
    cfg = WorkflowConfig.from_mapping(payload)

  client = NinjaSageClient(base_url=cfg.base_url)
  return NinjaSageWorkflow(client, cfg)


class NinjaSageHttpHandler(BaseHTTPRequestHandler):
  server_version = "NinjaSageHTTP/0.1"

  def _send_json(self, status: int, payload: Any) -> None:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    self.send_response(status)
    self.send_header("Content-Type", "application/json; charset=utf-8")
    self.send_header("Content-Length", str(len(body)))
    self.end_headers()
    self.wfile.write(body)

  def _read_json_body(self) -> dict[str, Any]:
    length = int(self.headers.get("Content-Length") or "0")
    if length <= 0:
      return {}
    raw = self.rfile.read(length)
    if not raw:
      return {}
    try:
      return json.loads(raw.decode("utf-8"))
    except json.JSONDecodeError:
      return {}

  # ------------------------------------------------------------------
  # Routing
  # ------------------------------------------------------------------

  def do_OPTIONS(self) -> None:  # type: ignore[override]
    self.send_response(204)
    self.send_header("Access-Control-Allow-Origin", "*")
    self.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
    self.send_header("Access-Control-Allow-Headers", "Content-Type")
    self.end_headers()

  def do_GET(self) -> None:  # type: ignore[override]
    if self.path == "/api/characters":
      self._handle_get_characters()
    else:
      self._send_json(404, {"error": "not_found"})

  def do_POST(self) -> None:  # type: ignore[override]
    if self.path == "/api/workflow":
      self._handle_workflow()
    else:
      self._send_json(404, {"error": "not_found"})

  # ------------------------------------------------------------------
  # Handlers
  # ------------------------------------------------------------------

  def _handle_workflow(self) -> None:
    data = self._read_json_body()
    username = data.get("username")
    password = data.get("password")

    override: dict[str, Any] | None = None
    if username and password:
      override = {
        "credentials": {
          "username": username,
          "password": password,
        }
      }

    try:
      workflow = _build_workflow(override)
      result = workflow.run()
    except Exception as exc:  # pragma: no cover - debugging helper
      self._send_json(
        502,
        {
          "error": "workflow_failed",
          "detail": str(exc),
        },
      )
      return

    payload = {
      "version": asdict(result.version),
      "analytics": asdict(result.analytics),
      "events": asdict(result.events),
      "login": asdict(result.login),
      "characters": asdict(result.characters),
      "character_data": asdict(result.character_data) if result.character_data is not None else None,
    }
    self._send_json(200, payload)

  def _handle_get_characters(self) -> None:
    """Endpoint ringkas untuk hanya mengambil daftar karakter."""

    try:
      workflow = _build_workflow(None)
      result = workflow.run()
    except Exception as exc:  # pragma: no cover - debugging helper
      self._send_json(
        502,
        {
          "error": "workflow_failed",
          "detail": str(exc),
        },
      )
      return

    self._send_json(200, asdict(result.characters))


def run(host: str = "127.0.0.1", port: int = 8080) -> None:
  server = HTTPServer((host, port), NinjaSageHttpHandler)
  print(f"[*] Ninja Sage API server berjalan di http://{host}:{port}")
  try:
    server.serve_forever()
  except KeyboardInterrupt:  # pragma: no cover - manual shutdown
    print("\n[*] Mematikan server...")
  finally:
    server.server_close()


if __name__ == "__main__":
  run()

