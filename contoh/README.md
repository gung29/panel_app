# Ninja Sage AMF Toolkit

Toolkit kecil berbasis Python yang membantu anda:

- membaca file AMF (`.amf`) yang diekspor dari Charles Proxy;
- membuat ulang envelope AMF menggunakan modul [Py3AMF](https://github.com/StdCarrot/Py3AMF);
- mengirim request ke endpoint `https://play.ninjasage.id/amf/<Service.method>` dengan header yang sama seperti klien Flash.

Semua utilitas ditempatkan di paket `ninja_sage` sehingga anda bisa menggunakannya lewat skrip atau interpreter Python.

> ⚠️ **Gunakan dengan bijak.** Pastikan aktivitas anda mengikuti ToS dari Ninja Sage. Kode di sini hanya contoh edukasi.

## 1. Instalasi

```bash
# Linux/macOS
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Windows PowerShell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

`requirements.txt` memasang `Py3AMF` (tersedia sebagai modul `pyamf`), `requests`, `rich`, dan `pycryptodome` (dipakai untuk AES-CBC di payload login).

> Jika saat menjalankan contoh muncul error `ModuleNotFoundError: No module named 'pyamf'`, berarti dependensi belum terpasang di virtualenv aktif. Jalankan ulang `pip install -r requirements.txt` di dalam environment tersebut.

## 2. Struktur singkat

```
.
├── ninja_sage/            # Paket utama (core + service per fitur)
├── run_workflow.py        # Program utama untuk menjalankan urutan request
├── config.example.json    # Contoh konfigurasi workflow
├── examples/              # Utilitas debugging opsional
├── requirements.txt
└── README.md
```

### Modul penting

- `ninja_sage.client.NinjaSageClient` – HTTP client dasar (header & POST AMF).
- `ninja_sage.models` – data-class request/response untuk semua service.
- `ninja_sage.services.system_login.SystemLoginService` – wrapper untuk `SystemLogin.checkVersion/loginUser/getAllCharacters`.
- `ninja_sage.services.analytics.AnalyticsService` – wrapper untuk `Analytics.libraries`.
- `ninja_sage.services.events.EventsService` – wrapper untuk `EventsService.get`.
- `ninja_sage.workflow` – contoh orchestrator yang memakai service-service di atas.

## 3. Konfigurasi workflow

Salin `config.example.json` menjadi `config.json` lalu isi dengan data yang anda miliki:

```json
{
  "base_url": "https://play.ninjasage.id",
  "channel": "Public 0.52",
  "credentials": {
    "username": "your_username",
    "password": "your_password"
  },
  "server_id": 12
}
```

Field penting (lihat `config.example.json`):

- `channel` – nilai `SystemLogin.checkVersion` (contoh: `Public 0.52`).
- `credentials.username / password` – data login anda.
- `server_id` (opsional) – dipakai saat `SystemLogin.getAllCharacters`. Default `12`.
- `include_events` (opsional) – set `false` jika ingin melewati `EventsService.get`.
- `analytics_base_url`, `library_url`, `loader_info` (opsional) – override sumber asset jika anda punya mirror sendiri.
- `character_seed`, `character_key` (opsional) – isi manual jika `SystemLogin.checkVersion` tidak mengembalikan field `_` / `__` pada environment anda.

Sisanya dihitung otomatis:

- Payload `Analytics.libraries` dibuat ulang dari daftar asset di `analytics_base_url` (mirip script `get-analytic-libraries.py`).
- Payload `SystemLogin.loginUser` dibangun dari username/password menggunakan logika AES, CUCSG, dan library level seperti pada `get-login.py`. Nilai `character_seed` dan `character_key` diambil dari hasil `checkVersion` (atau dari config bila anda override), sedangkan `specific_item`/`random_seed` dihitung dari `library.bin`.

Pastikan anda punya koneksi yang cukup karena proses ini akan mengunduh berbagai `.bin` dari CDN sebelum mengirim request AMF.

## 4. Menjalankan urutan request

```bash
# Linux/macOS
python3 run_workflow.py --config config.json

# Windows PowerShell
py -3 run_workflow.py --config config.json
```

Program akan otomatis menjalankan urutan berikut:

1. `SystemLogin.checkVersion`
2. `Analytics.libraries`
3. `EventsService.get`
4. `SystemLogin.loginUser`
5. `SystemLogin.getAllCharacters`

Setiap respons dipetakan ke model `CheckVersionResponse`, `AnalyticsLibrariesResponse`, `EventsServiceGetResponse`, `SystemLoginResponse`, dan `GetAllCharactersResponse`. Output CLI menampilkan isi data-class tersebut sehingga mudah dianalisis atau dipakai ulang di kode anda.

> Catatan: tahap `Analytics.libraries` dan pembuatan payload login akan mengunduh beberapa `.bin` dari CDN Ninja Sage. Data disimpan di cache in-memory, jadi panggilan workflow berikutnya dalam proses yang sama tidak mengulang download.

Anda bisa mengimpor `WorkflowConfig` dan `NinjaSageWorkflow` langsung di proyek lain untuk mendapatkan objek `WorkflowResult` tanpa menjalankan CLI.

## 5. Menggunakan model secara programatik

```python
from ninja_sage import (
    NinjaSageClient,
    WorkflowConfig,
    NinjaSageWorkflow,
)

config = WorkflowConfig.from_file("config.json")
client = NinjaSageClient(base_url=config.base_url)
workflow = NinjaSageWorkflow(client, config)
result = workflow.run()

print(result.login.uid, result.login.sessionkey)
for character in result.characters.characters:
    print(character.character_id, character.name, character.level)
```

Semua request dan response memiliki data-class, sehingga anda tidak perlu menebak struktur dictionary yang dikembalikan Py3AMF.

## 6. Utilitas debugging opsional

Folder `examples/` berisi skrip tambahan untuk membaca file AMF mentah (`decode_capture.py`) atau mengirim request manual (`dispatch.py`). Ini membantu ketika anda ingin mengecek hasil export dari Charles Proxy atau membuat payload custom.

## 7. Tips debugging

- **Hex/Raw**: ketika menyalin request dari Charles, simpan raw body sebagai file `.amf` lalu jalankan `decode_capture.py` untuk memastikannya.
- **Diff request**: `NinjaSageClient.describe(envelope)` akan memberikan ringkasan berguna sebelum mengirim payload.
- **Masalah autentikasi**: perhatikan nilai pada field `hash`, `sessionkey`, dll. Biasanya server akan menolak jika timestamp/signature kadaluarsa.

Dengan struktur ini anda sudah memiliki fondasi untuk membangun klien Ninja Sage versi Python yang dapat membaca dan mengirim AMF request mirip aplikasi Flash aslinya.
