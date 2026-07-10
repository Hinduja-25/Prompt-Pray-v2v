# SheDefends 🚨❤️

A premium, modern personal safety, health, and wellness application for women. SheDefends empowers users through live location monitoring, quick emergency SOS broadcasts, simulated decoy tools, AI health analysis, mood insights, and an empathetic chatbot companion.

---

## 🌟 Key Features

### 1. Safety Shield 🛡️
* **Guardian Mode**: Track journeys in real-time. Share live GPS coordinates and estimated arrival times with chosen emergency contacts.
* **Overpass API Integration**: Query live OpenStreetMap points of interest (hospitals, police stations, pharmacies, community centers) within 5 km of the user's GPS coordinates, sorted by proximity.
* **Stealth & Decoy Calculator Lock**: A fully functional calculator decoy screen. Entering the correct PIN unlocks the real application, while a **Silent SOS** can be triggered directly in case of emergency.
* **Fake Call Simulator**: Schedule decoy voice calls to exit uncomfortable or unsafe situations.
* **Siren Sound Emergency Alert**: Loops a loud emergency police siren, which stops immediately when clicking **"I am Safe – Terminate SOS"**.

### 2. AI Chatbot Companion 💬
* **Empathetic Companion**: Conversational assistant built with advanced LLM routing.
* **Self-Healing Key Support**: Automatically routes keys based on prefixes (OpenAI `sk-` or Groq `gsk_`) to prevent API authentication blocks.
* **Deep Routing**: Directs users straight to specific parts of the app (e.g. suggesting the Symptom Checker when describing a headache).

### 3. Wellness Center 🧘‍♀️
* **Mood Tracker**: Log daily feelings and visualize historical emotional wellness logs.
* **Interactive Journaling**: Reflect on daily thoughts with backend AI sentiment and theme analysis.
* **Guided Breathing**: Simple, interactive animation to relax, focus, and ground yourself.

### 4. Health Dashboard 🏥
* **Symptom Checker**: Describe symptoms to receive an empathetic condition assessment, severity ratings, self-care suggestions, dietary recommendations, and warning signs.
* **Medication Logger**: Sync and monitor medications to maintain daily wellness routines.

---

## 🛠️ Project Structure

The project is structured as a monorepo containing two main folders:
1. `she_defends_app/`: The Flutter client frontend application.
2. `she_defends_backend/`: The Flask REST API service written in Python.

---

## 🚀 Getting Started

### 1. Backend Service Configuration (`she_defends_backend`)

1. Navigate to the backend folder:
   ```bash
   cd she_defends_backend
   ```
2. Create and activate a Python virtual environment:
   ```bash
   python -m venv venv
   # On Windows (Powershell)
   .\venv\Scripts\Activate.ps1
   # On macOS/Linux
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Configure environment variables in `.env`:
   ```env
   PORT=5000
   MONGO_URI=your_mongodb_atlas_uri
   FIREBASE_CREDENTIALS_PATH=shedefends-firebase-adminsdk.json
   GEMINI_API_KEY=your_gemini_api_key
   OPENAI_API_KEY=your_openai_or_groq_api_key
   CLOUDINARY_CLOUD_NAME=your_cloudinary_name
   CLOUDINARY_API_KEY=your_cloudinary_key
   CLOUDINARY_API_SECRET=your_cloudinary_secret
   ```
5. Run the server:
   ```bash
   python app.py
   ```
   *The server runs at `http://localhost:5000` and displays its local network IP.*

---

### 2. Frontend Client Configuration (`she_defends_app`)

1. Navigate to the app folder:
   ```bash
   cd she_defends_app
   ```
2. Verify dynamic host discovery:
   *SheDefends incorporates self-healing dynamic host discovery. On application startup, it pings the local loopbacks and PC Wi-Fi LAN IP to dynamically select the working endpoint. Physical devices on the same Wi-Fi will connect automatically without requiring manually edited IP addresses!*
3. Fetch dependencies and run:
   ```bash
   flutter pub get
   flutter run
   ```

---

## 🧪 Verification & Tests

### Backend API Tests
* Test endpoints locally:
  ```bash
  python scratch/test_unregistered.py
  python scratch/test_safe_places_api.py
  ```

### Flutter Tests
* Run unit tests and static analyses:
  ```bash
  flutter test
  flutter analyze
  ```

---

## 📝 Authors & License

Developed with love for **SheDefends App** — personal health, safety, and wellness companion.
