# RGV Tutor

## Purpose

RGV Tutor is an offline-first Flutter MVP for math practice. It provides short multiple-choice problems, tracks mastery per skill, and recommends what to practice next.

### Features

- Adaptive recommendations (simple mastery model)
- Animated XP bar + mastery bars
- Instant feedback burst + shake on wrong answers

## Dependencies (install once)

### 0) Git (recommended)

```powershell
winget install Git.Git
git --version
```

### 1) Flutter SDK

- Install Flutter: https://docs.flutter.dev/get-started/install
- Verify:

```bash
flutter --version
flutter doctor
```

### 2) Node.js (local API server)

Windows (PowerShell) install:

```powershell
winget install OpenJS.NodeJS.LTS
```

Verify:

```bash
node --version
npm --version
```

### 3) Ollama (local helper bot / offline AI)

The app includes a local “Helper Bot” that talks to Ollama at `http://localhost:11434`.

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
ollama pull llama3.2:1b
```

Pull the model used by the app (default: `llama3.2:1b`):

```powershell
 & "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" pull llama3.2:1b
```

Verify the Ollama server is running:

```powershell
curl.exe http://localhost:11434/api/tags
```

If you’re running the app on an Android emulator, it will use `http://10.0.2.2:11434` to reach the host.

### 4) Python (optional, dev tooling)

Only needed if you want to run scripts in `tools/`.

```bash
python --version
```

## Install project dependencies

From this folder:

```bash
flutter pub get
```

## Run the app

```bash
flutter run
```

### Run on web

```bash
flutter run -d chrome --dart-define=BOOK_PROXY_URL=http://localhost:8080/api/proxy
```

## Local API server (for web/CORS + online mode)

This repo includes a small local server you can run during development to:

- Provide a stable API base URL for “online mode”
- Proxy third-party resources (images, files) to avoid browser CORS blocks

Run it in a second terminal:

```bash
cd server
npm install
npm run dev
```

Endpoints:

- `GET http://localhost:8080/health`
- `GET http://localhost:8080/api/proxy?url=<https-url>`

### Run on Windows desktop

```bash
flutter run -d windows
```

### Run on Android

1) Install Android Studio + Android SDK.
2) Run `flutter doctor` and ensure the Android toolchain is green.
3) Connect a device (or start an emulator) and run:

```bash
flutter run -d <device-id>
```

If you’re missing platform folders (`android/`, `ios/`, `web/`, etc.):

```bash
flutter create .
flutter pub get
```

If you see errors like `'C:\Users\Jonathan' is not recognized...` on Windows, move the project to a path without spaces (for example `C:\src\rgv_tutor`) and try again.
