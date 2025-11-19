import zlib
import json
from pathlib import Path
from urllib import request, parse
from json import JSONDecodeError

# Daftar URL yang mau di-download
URLS = [
    "https://ns-assets.ninjasage.id/static/lib/skills.bin",
    "https://ns-assets.ninjasage.id/static/lib/library.bin",
    "https://ns-assets.ninjasage.id/static/lib/npc.bin",
    "https://ns-assets.ninjasage.id/static/lib/enemy.bin",
    "https://ns-assets.ninjasage.id/static/lib/mission.bin",
    "https://ns-assets.ninjasage.id/static/lib/pet.bin",
    "https://ns-assets.ninjasage.id/static/lib/gamedata.bin",
    "https://ns-assets.ninjasage.id/static/lib/talents.bin",
    "https://ns-assets.ninjasage.id/static/lib/senjutsu.bin",
    "https://ns-assets.ninjasage.id/static/lib/skill-effect.bin",
    "https://ns-assets.ninjasage.id/static/lib/weapon-effect.bin",
    "https://ns-assets.ninjasage.id/static/lib/back_item-effect.bin",
    "https://ns-assets.ninjasage.id/static/lib/accessory-effect.bin",
    "https://ns-assets.ninjasage.id/static/lib/arena-effect.bin",
    "https://ns-assets.ninjasage.id/static/lib/animation.bin",
]


def download_and_decompress(url: str, output_dir: Path):
    """Download satu file .bin dari URL, decompress, lalu simpan sebagai .json atau .txt."""
    output_dir.mkdir(parents=True, exist_ok=True)

    # Ambil nama file dari URL, misal "gamedata.bin"
    path = parse.urlparse(url).path
    filename = Path(path).name  # e.g. gamedata.bin
    bin_name = filename or "data.bin"

    print(f"\n=== Memproses: {url}")
    print(f"    Nama file: {bin_name}")

    # Download data biner (tanpa harus simpan file .bin kalau tidak mau)
    with request.urlopen(url) as resp:
        data = resp.read()

    print(f"    Ukuran file ter-download: {len(data)} byte")

    # Coba decompress dengan zlib
    try:
        decompressed = zlib.decompress(data)
    except zlib.error as e:
        print(f"    ❌ Gagal decompress (bukan format zlib?): {e}")
        return

    print(f"    Ukuran setelah decompress: {len(decompressed)} byte")

    # Coba decode sebagai UTF-8
    try:
        text = decompressed.decode("utf-8")
    except UnicodeDecodeError as e:
        print(f"    ❌ Gagal decode UTF-8: {e}")
        # Kalau tidak bisa decode, simpan raw biner yang sudah decompress
        out_raw = output_dir / (Path(bin_name).stem + ".raw")
        out_raw.write_bytes(decompressed)
        print(f"    🔹 Disimpan sebagai raw biner: {out_raw}")
        return

    # Coba parse sebagai JSON
    stem = Path(bin_name).stem  # "gamedata" dari "gamedata.bin"

    try:
        obj = json.loads(text)
        out_json = output_dir / f"{stem}.json"
        with out_json.open("w", encoding="utf-8") as f:
            json.dump(obj, f, ensure_ascii=False, indent=2)
        print(f"    ✅ Berhasil: disimpan sebagai JSON → {out_json}")
    except JSONDecodeError:
        # Kalau bukan JSON valid, simpan sebagai .txt
        out_txt = output_dir / f"{stem}.txt"
        out_txt.write_text(text, encoding="utf-8")
        print(f"    ⚠️ Bukan JSON valid, disimpan sebagai teks → {out_txt}")


def main():
    # Folder output (boleh ganti sendiri)
    output_dir = Path("output_json")

    for url in URLS:
        try:
            download_and_decompress(url, output_dir)
        except Exception as e:
            print(f"    ❌ Error tak terduga untuk {url}: {e}")


if __name__ == "__main__":
    main()
