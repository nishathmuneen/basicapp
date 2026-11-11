# My Health Tracker (Flutter)

A simple, mobile-friendly personal health monitoring app built completely in **Flutter** with on-device **SQLite** persistence on Android/iOS (`sqflite`), local JSON persistence in `%APPDATA%\MyHealthTracker` on Windows, and `localStorage` persistence on Web.

## Features

- **Single-Patient Sign-In & Login Details:** Default login (`patient` / `health123`) with salted password hashing and an in-app **Login Details** editor for updating your name, username, and password.
- **Home Dashboard:** Welcome message, overall health status (`Normal`, `Warning`, or `Critical`), last recording date & time, latest blood glucose, blood pressure, and heart rate cards, due reminders, and large **Add Glucose Reading** & **Add BP Reading** buttons.
- **Record Blood Glucose:** Log glucose (`mg/dL`), reading type (`Fasting`, `Before Meal`, `After Meal`, `Random`), and date/time with automatic target-range evaluation.
- **Record Blood Pressure:** Log systolic, diastolic, optional heart rate, and date/time with color-coded status (`Green: Normal`, `Yellow: Attention`, `Red: Urgent`).
- **Automatic Warnings & Configurable Thresholds:** Clinically reviewed defaults with non-diagnostic guidance messages and customizable target ranges.
- **Health History:** View Daily, Weekly, Monthly, or All readings with Date, Time, Glucose value, BP value, Status, and delete confirmation.
- **Simple Charts:** Blood glucose and blood pressure trend graphs showing whether readings are increasing, decreasing, or steady.
- **Reminders:** Configure daily reminders for Morning glucose check, Evening glucose check, and BP measurement.

## Default Login Details

- **Username:** `patient`
- **Password:** `health123`

After signing in, tap the profile icon in the top bar (**Login Details**) to set your preferred name, username, and password.

## Download Android APK (GitHub)

Every push to `main` automatically builds and publishes a signed Android APK via GitHub Actions (`.github/workflows/build-apk.yml`).

### Option 1: Direct Download from GitHub Releases (Recommended on Phone)
1. Open the repository on GitHub: https://github.com/nishathmuneen/basicapp
2. Click **Releases** (or go directly to https://github.com/nishathmuneen/basicapp/releases/latest).
3. Under **Assets**, download **`MyHealthTracker.apk`**.
4. Open the downloaded `.apk` file on your Android phone (allow **Install unknown apps** for your browser/files app if prompted).

### Option 2: Download from GitHub Actions Artifacts
1. Open the **Actions** tab in the GitHub repository and select **Build Android APK**.
2. Click the latest green completed workflow run (or click **Run workflow** to trigger one manually).
3. Scroll to **Artifacts** and download **`MyHealthTracker-apk`**, then unzip it to get **`MyHealthTracker.apk`**.

## Run & Test Locally

From `flutter_app/`:

```powershell
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter run          # Launches on Windows desktop (no Developer Mode required)
flutter run -d chrome
```
