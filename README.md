# RGV Tutor

RGV Tutor is an offline-first Flutter app for learning and study support. It offers short multiple-choice problems, tracks mastery per skill, recommends what to practice next, and includes a Book Hub for reading curated learning materials. An optional in-app “Helper Bot” can connect to a local Ollama model for extra guidance with support for Calendar/Planning and custom Quizzes/Flashcard creation + sharing.

![RGV Tutor home screen](<Screenshot 2026-04-19 024910.png>)

## Purpose

RGV Tutor is designed for learners in areas with little to no internet access. The goal is to make high-quality learning materials usable in low-connectivity environments by keeping the core experience offline-first and enabling content to be saved directly on the device.

The Book Hub provides free books via standard HTTP URLs (treat these as “API endpoints”) listed in the bundled catalog (`assets/books.json`). On mobile/desktop builds, books can be downloaded once and stored locally, so students can keep reading without a connection (web builds stream from the remote URL).

## Repo layout

- `lib/`: Flutter app source
- `assets/`: offline problem + book catalogs
- `server/`: small local Node server used as a CORS-safe proxy for web builds
- `tools/`: optional dev scripts

## Prerequisites

### Git (recommended)

```powershell
winget install Git.Git
git --version
```

### Flutter SDK

- Install: https://docs.flutter.dev/get-started/install
- Verify:

```bash
flutter --version
flutter doctor
```

### Node.js (only if you want the local proxy server)

```powershell
winget install OpenJS.NodeJS.LTS
node --version
npm --version
```

### 3) Ollama (local Helper Bot / offline AI)

The app includes a local “Helper Bot” that talks to Ollama’s HTTP API at:

- Web / desktop: `http://localhost:11434`
- Android emulator: `http://10.0.2.2:11434`

Windows (PowerShell) install:

```powershell
winget install Ollama.Ollama
```

If `ollama` isn’t found on your PATH after installing, use the full path:

```powershell
& "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" --version
```

If you added Ollama to PATH (or the installer did) but your current PowerShell session still can’t find it, refresh PATH in this session and re-check:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
where.exe ollama
ollama --version
```

Pull the model used by the app (default: `llama3.2:1b`):

```powershell
ollama pull llama3.2:1b
```

Or using the full path:

```powershell
& "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" pull llama3.2:1b
```

Verify the Ollama server is up:

```powershell
curl.exe http://localhost:11434/api/tags
```

### Python (optional: scripts in `tools/`)

```bash
python --version
```

## Quickstart (Flutter)

From `RGV_Tutor/`:

```bash
flutter pub get
flutter run
```

### Run on Windows desktop

```bash
flutter run -d windows
```

### Run on Android

```bash
flutter run -d <device-id>
```

## Run on web (Chrome)

The web build can hit CORS issues when fetching remote EPUB/PDF/book assets. To avoid that, run the local proxy server and pass `BOOK_PROXY_URL`.

1) Start the local proxy server in a second terminal:

```bash
cd server
npm install
npm run dev
```

By default it listens on `http://localhost:8080`, but if `8080` is taken it will try the next ports (unless you set `PORT`).

Optional environment variables:

- `PORT`: force a specific port (disables auto-increment)
- `CORS_ORIGIN`: allowed CORS origin (default `*`)

Endpoints:

- `GET http://localhost:8080/health`
- `GET http://localhost:8080/api/proxy?url=<https-url>`

2) Run the Flutter app on web with the proxy base URL:

```bash
flutter run -d chrome --dart-define=BOOK_PROXY_URL=http://localhost:8080/api/proxy
```

This proxy is also used for book cover images when `BOOK_PROXY_URL` is set.

If the server chose a different port, update the URL accordingly.

## Dev scripts

- Regenerate/sync the bundled book list: `python tools/generate_books.py`

## Troubleshooting

- Missing platform folders (`android/`, `ios/`, `web/`, etc.): run `flutter create .` then `flutter pub get`.
- Windows path issues: if builds fail in a path with spaces, try moving the repo to a short path like `C:\src\rgv_tutor`.
