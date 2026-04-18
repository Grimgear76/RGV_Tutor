# RGV Tutor

## Purpose

RGV Tutor is an offline-first Flutter MVP for math practice. It provides short multiple-choice problems, tracks mastery per skill, and recommends what to practice next.

### Features

- Adaptive recommendations (simple mastery model)
- Animated XP bar + mastery bars
- Instant feedback burst + shake on wrong answers

## Run the app

From this folder:

```bash
flutter pub get
flutter run
```

### Run on web

```bash
flutter run -d chrome
```

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

If you see errors like `'C:\Users\Jonathan' is not recognized...` on Windows, move the project to a path without spaces (for example `C:\src\rgv_math_tutor`) and try again.
