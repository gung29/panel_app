"""Interactive CLI that mimics the real Ninja Sage login flow."""

from __future__ import annotations

import argparse
import getpass

from rich import print
from rich.console import Console

from ninja_sage import (
    AnalyticsService,
    EventsService,
    NinjaSageClient,
    SystemLoginService,
    WorkflowConfig,
)
from ninja_sage.models import WorkflowResult


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        default="config.json",
        help="Path to the workflow configuration file (default: config.json)",
    )
    parser.add_argument("--username", help="Override username from config (if any)")
    parser.add_argument("--password", help="Override password from config (if any)")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    config = WorkflowConfig.from_file(args.config)
    console = Console()

    # ------------------------------------------------------------------
    # Input kredensial
    # ------------------------------------------------------------------
    username = args.username or getattr(config, "credentials", None).username if hasattr(config, "credentials") else None
    password = args.password or getattr(config, "credentials", None).password if hasattr(config, "credentials") else None

    if not username:
        username = input("Username: ").strip()
    if not password:
        password = getpass.getpass("Password: ").strip()

    client = NinjaSageClient(base_url=config.base_url)
    sys_login = SystemLoginService(client, loader=config.loader, library_url=config.library_url)
    analytics = AnalyticsService(client, base_url=config.analytics_base_url)
    events_service = EventsService(client)

    # ------------------------------------------------------------------
    # 1. checkVersion
    # ------------------------------------------------------------------
    version = sys_login.check_version(channel=config.channel)
    console.rule("[bold cyan]SystemLogin.checkVersion[/bold cyan]")
    console.print(version)

    # ------------------------------------------------------------------
    # 2. Analytics & Events
    # ------------------------------------------------------------------
    analytics_resp = analytics.libraries()
    console.rule("[bold cyan]Analytics.libraries[/bold cyan]")
    console.print(analytics_resp)

    events_resp = events_service.get()
    console.rule("[bold cyan]EventsService.get[/bold cyan]")
    console.print(events_resp)

    # ------------------------------------------------------------------
    # 3. loginUser
    # ------------------------------------------------------------------
    login_resp = sys_login.login_user(
        username=username,
        password=password,
        character_seed=version.character_seed,
        character_key=version.character_key,
    )
    console.rule("[bold cyan]SystemLogin.loginUser[/bold cyan]")
    console.print(login_resp)

    # ------------------------------------------------------------------
    # 4. getAllCharacters & pilih karakter
    # ------------------------------------------------------------------
    chars_resp = sys_login.get_all_characters(login_resp, server_id=config.server_id)
    console.rule("[bold cyan]SystemLogin.getAllCharacters[/bold cyan]")
    for idx, ch in enumerate(chars_resp.characters):
        console.print(f"[{idx}] {ch.name} (Lv {ch.level}) cid={ch.char_id}")

    if not chars_resp.characters:
        console.print("[red]Tidak ada karakter yang tersedia.[/red]")
        return

    default_idx = getattr(config, "selected_character_index", 0)
    try:
        raw = input(f"Pilih indeks karakter [default {default_idx}]: ").strip()
        selected_idx = int(raw) if raw else default_idx
    except ValueError:
        selected_idx = default_idx

    selected_idx = max(0, min(selected_idx, len(chars_resp.characters) - 1))
    selected = chars_resp.characters[selected_idx]
    console.print(f"Karakter terpilih: [bold]{selected.name}[/bold] (cid={selected.char_id})")

    # ------------------------------------------------------------------
    # 5. getCharacterData
    # ------------------------------------------------------------------
    char_data = sys_login.get_character_data(selected.char_id, login_resp.sessionkey)
    console.rule("[bold cyan]SystemLogin.getCharacterData[/bold cyan]")
    console.print(char_data)

    # ------------------------------------------------------------------
    # Ringkasan hasil sebagai WorkflowResult (opsional)
    # ------------------------------------------------------------------
    summary = WorkflowResult(
        version=version,
        analytics=analytics_resp,
        events=events_resp,
        login=login_resp,
        characters=chars_resp,
        character_data=char_data,
    )

    console.rule("[bold green]Ringkasan WorkflowResult[/bold green]")
    console.print(summary)


if __name__ == "__main__":
    main()
