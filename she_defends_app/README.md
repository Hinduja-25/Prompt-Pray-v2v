# SheDefends Flutter Application 📱✨

This directory contains the Flutter client frontend application for the **SheDefends** personal safety, health, and wellness platform.

---

## 🚀 Key Client Modules

### 1. Safety Shield (`lib/features/safety`)
* **Guardian Mode Route Maps**: Displays estimated arrival time and routes, with standard safety features.
* **Overpass API Nearby safe places**: Dynamically checks coordinates (e.g. `20.2646, 85.8242`) and shows real-time nearby police stations, hospitals, and pharmacies.
* **Stateful Siren Controller**: Emergency sound alarm looped via the `audioplayers` package, structured to stop immediately on user termination.
* **Calculator PIN Decoy**: A functional math calculator hiding the actual app lock screen.

### 2. Health Center (`lib/features/health`)
* **Symptom Input & Logs**: Record wellness details and query backend diagnostics.
* **Medication Manager**: Synchronize local logs with persistent database records.

### 3. Wellness Center (`lib/features/wellness`)
* **Mood Tracker**: Log daily emotional wellness levels.
* **AI Journaling**: Input daily reflections and get theme insights.
* **Guided Breathing**: Grounding exercises using smooth animations.

### 4. Interactive Chat Companion (`lib/features/assistant`)
* **Chat Panel**: An overlay drawer featuring chatbot responses powered by fallback models (Groq Llama & OpenAI GPT).

---

## 🛠️ Tech Stack & Packages

* **State Management**: `flutter_riverpod` for clean state caching and updates.
* **HTTP Networking**: `dio` for secure backend REST queries and interceptors.
* **Audio Playback**: `audioplayers` for looped siren alarms and Fake Call ringtones.
* **GPS Tracking**: `geolocator` for coordinate streams and current location checks.
* **Device Interaction**: `url_launcher` for deep-linking SMS alerts and Google Maps directions.

---

## 🛜 Network Resilience & Host Auto-Discovery

To streamline local cross-device debugging, `api_client.dart` features **Dynamic Base URL Auto-Discovery** on app startup:
* **The Problem**: Hardcoding `localhost` doesn't work on mobile devices. Hardcoding emulator loopbacks (`10.0.2.2`) doesn't work on physical phones.
* **The Solution**: On launch, the app dynamically pings a list of candidate base URLs (emulator host, local machine Wi-Fi LAN IP `192.168.29.128`, and `localhost`). Whichever endpoint responds is selected automatically.
* **Debugging**: Ensure your physical device (`SM A356E`) is on the same Wi-Fi network as your host machine.

---

## 🏃 Run Instructions

1. Retrieve Flutter packages:
   ```bash
   flutter pub get
   ```
2. Check for code quality:
   ```bash
   flutter analyze
   ```
3. Run unit tests:
   ```bash
   flutter test
   ```
4. Build and run debug mode:
   ```bash
   flutter run
   ```
