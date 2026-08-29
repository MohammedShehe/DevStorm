# MediTrack — Medicine Reminder & Dosage Tracker

Full-stack app: **Flutter** frontend + **Node.js / Express / Sequelize / MySQL** backend.

## Fixes included in this package

- Shared singleton `ApiService` so JWT is used by all providers
- Login stores JWT; session restored via `SharedPreferences`
- Splash waits for session restore
- Caregiver screen calls real API
- Family members screen + profile navigation
- Drawer / profile: Privacy, Terms, FAQs, About, Support screens
- Dose **taken** decrements medicine stock
- Past upcoming doses auto-marked **missed** on fetch
- Dose log generation capped at 30 days (chunked inserts)
- Medicine routes: scan/voice registered before `:id`
- Report export returns real CSV/summary data
- Email skipped cleanly when SMTP not configured
- Secrets removed from `.env` (placeholders only)
- Android emulator API host default: `http://10.0.2.2:5000/api`

## Backend setup

```bash
cd backend
cp .env.example .env   # or edit .env
# Set DB_PASSWORD, JWT_SECRET, optional MAIL_*
npm install
# Create MySQL database: CREATE DATABASE meditrack;
npm run dev
```

Server: `http://localhost:5000`

## Frontend setup

```bash
cd frontend/medicinetracker
flutter pub get
```

### API base URL

Default in code (Android emulator → host machine):

`http://10.0.2.2:5000/api`

Override at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000/api
```

iOS simulator can use `http://localhost:5000/api`. Physical devices need your PC's LAN IP.

```bash
flutter run
```

## Main API routes

| Prefix | Purpose |
|--------|---------|
| `/api/auth` | register, login, OTP, reset, logout, refresh |
| `/api/users` | profile, caregivers |
| `/api/medicines` | CRUD, low-stock, scan, voice |
| `/api/doses` | today, upcoming, mark taken/skipped/missed |
| `/api/notifications` | settings |
| `/api/reports` | adherence, export |
| `/api/preferences` | theme / accessibility |
| `/api/caregivers` | notes |
| `/api/family-members` | family links |

## Notes

- Barcode / voice endpoints still return **demo** medicine payloads (no camera/mic packages). UI calls the API and fills the form.
- Local push notifications are not implemented (settings are stored only).
- PDF export returns structured JSON for client-side generation; CSV returns a CSV string in JSON.


## Local notifications (Android / iOS)

The app uses `flutter_local_notifications` to schedule dose alerts.

### Android (`android/app/src/main/AndroidManifest.xml`)

Ensure these permissions exist inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

Inside `<application>`, receivers from the plugin are usually auto-merged via the package. After changing permissions:

```bash
flutter pub get
flutter clean
flutter run
```

Allow notifications when the system prompts you. Use **Notification Settings → Send Test Notification** to verify.


## Barcode scanner

Uses the device camera via `mobile_scanner`.

### Android

In `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

Optional in `<application>` / activity if needed for cleartext not related to camera.

### iOS

In `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is used to scan medicine package barcodes.</string>
```

Then:

```bash
flutter pub get
flutter run
```

Point the camera at a barcode or type the number manually. The app looks up the code via Open Food Facts and a local catalog, then fills the Add Medicine form.


## Medicine search (external APIs)

Name suggestions and detail cards use:

1. **RxNorm** (U.S. National Library of Medicine) — name suggestions  
2. **OpenFDA** drug labels — uses, warnings, dosage text  
3. Local curated fallback when networks fail  

No API key required for RxNorm/OpenFDA.

## AI chatbot

Floating **AI Help** button opens a chat with premade question templates.

- Set `OPENAI_API_KEY` in `backend/.env` for live OpenAI answers (`OPENAI_MODEL` defaults to `gpt-4o-mini`).
- If the key is empty, the server returns helpful local template answers.

```env
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
```


## Free AI chatbot keys

Priority order: **Groq → Gemini → OpenAI → offline**.

### Groq (recommended free)
1. Create key: https://console.groq.com/keys  
2. In `backend/.env`:

```env
GROQ_API_KEY=gsk_your_key_here
GROQ_MODEL=llama-3.1-8b-instant
```

### Google Gemini (free)
1. Create key: https://aistudio.google.com/apikey  
2. In `backend/.env`:

```env
GEMINI_API_KEY=your_key_here
GEMINI_MODEL=gemini-2.0-flash
```

Restart the backend after saving `.env`.
