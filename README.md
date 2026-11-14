# 💊 MediBond BD

### Smart Medicine Reminder & Family Health Organizer

**Your Medicine. Your Schedule. Your Family.**

MediBond BD is an Android-first, offline-focused medication reminder and family health organization application built with Flutter.

Developed by **Abdur Rahaman Abdulla (CatHaxor)** — A Nethivo Product.

The application is designed to help individuals and families organize medication schedules, track medicine intake, manage family health profiles, and keep important medical documents accessible.

---

## ✨ Features

### 💊 Medicine Management
- Add, edit, and manage medicines.
- Set daily or weekly medicine schedules.
- Configure multiple reminder times.
- Track active and archived medicines.
- Organize medicines by family member.

### 🔔 Smart Medication Reminders
- Local Android notifications.
- Scheduled medication alerts.
- Taken, Skip, and Snooze actions.
- Offline reminder functionality.
- Medication schedule tracking.

*Reminder delivery depends on Android notification permissions, battery restrictions, and device settings.*

### 👨‍👩‍👧‍👦 Family Health Profiles
- Create and manage family profiles.
- Store personal information locally.
- Record optional blood group and health information.
- Manage individual medication schedules.
- Edit or update family information.

### 📊 Medication History
- Daily medication history.
- Taken, Pending, Skipped, and Missed tracking.
- Medication timeline.
- History filtering and summary views.

### 📁 Prescription Vault
- Organize prescription documents.
- Access stored medical documents.
- Local document management.
- Privacy-conscious storage.

### 🔐 Privacy & Security
- Local-first health data storage.
- Account authentication through Supabase.
- Local database using SQLite and Drift.
- App security and privacy controls.
- Encrypted backup and restore functionality, where supported by the installed build.

### ☁️ Supabase Authentication
- Email and password registration.
- User login and logout.
- Password reset.
- Authentication session management.
- Remote app release information.

**Important:** Supabase is intended for authentication and non-sensitive application services. Personal health records, medicines, prescriptions, and medication history are designed to remain locally stored.

### 📱 Additional Features
- Bangla and English language support.
- Material 3 interface.
- Light and dark appearance.
- Theme customization.
- App update checking.
- Offline access for previously authenticated users.

---

## 🛠️ Technology Stack

| Component | Technology |
|---|---|
| Mobile Framework | Flutter |
| Programming Language | Dart |
| State Management | Riverpod |
| Navigation | GoRouter |
| Local Database | Drift + SQLite |
| Authentication | Supabase Auth |
| Remote Configuration | Supabase PostgreSQL |
| Notifications | Flutter Local Notifications |
| Platform | Android |
| Design | Material 3 |

---

## 📱 Android Compatibility

**Target support:** Android 10 through Android 17 (API 29–37).

Compatibility across this entire range is a development goal. Individual Android versions, device manufacturers, and notification behavior require validation before full support can be guaranteed.

---

## 🚀 Getting Started

### Prerequisites

Install the following tools:

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android SDK
- Git
- A compatible Android emulator or physical Android device

Flutter installation guide: https://docs.flutter.dev/get-started/install

### 1. Clone the Repository

```bash
git clone https://github.com/cathaxor/MediBond-BD.git
cd MediBond-BD
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

Create a Supabase project at:

https://supabase.com

Obtain the following values:

- Supabase Project URL
- Supabase Publishable Key

Configure the Flutter application using build-time environment variables.

Example:

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_PROJECT_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Verify the variable names against the current `SupabaseConfig` implementation before running.

**Security:** Never expose Supabase service-role keys, database passwords, SMTP passwords, or release signing credentials in the repository.

The Supabase project also requires the appropriate Authentication settings and database migrations for enabled cloud features.

### 4. Run the Application

Connect an Android device or start an emulator.

```bash
flutter devices
flutter run
```

### 5. Run Tests

```bash
flutter analyze
flutter test
```

### 6. Build an Android APK

For development:

```bash
flutter build apk --debug
```

For distribution, configure a dedicated Android release signing key and appropriate release settings before building:

```bash
flutter build apk --release
```

Never distribute a production release signed with the debug keystore.

---

## 📂 Project Structure

The application follows a feature-oriented Flutter architecture.

Key project directories include:

```text
medibond_bd/
├── android/
├── assets/
├── lib/
│   ├── core/
│   ├── data/
│   └── ...
├── test/
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

The exact internal directory structure may evolve during development.

---

## 🔒 Privacy & Local Data

MediBond BD follows a local-first approach to health information.

Medication details, family health records, prescriptions, and medication history are intended to be managed on the user's device rather than automatically uploaded to Supabase.

Supabase provides account authentication and application-level services.

### Backup and Restore

Encrypted backup export/import is intended to support secure, user-controlled device migration.

Users should keep backup files and passwords safe. If a backup password is lost, the encrypted data may not be recoverable.

**Note:** Uninstalling the application or clearing its storage can permanently remove local data that has not been independently backed up.

---

## 📦 Releases & Updates

Android application releases will be published through GitHub Releases when available.

**[View GitHub Releases](https://github.com/cathaxor/MediBond-BD/releases)**

The application is designed to check Supabase-hosted release metadata for update availability.

Creating a release record does not automatically install a new APK. Updates must be distributed through a trusted release channel.

---

## 🩺 Medical Disclaimer

MediBond BD is a medication organization and reminder utility.

It does not provide medical diagnoses, prescribe medicines, or replace advice from qualified healthcare professionals.

Users should follow their healthcare provider's instructions when taking medication.

---

## 👨‍💻 Developer

**Abdur Rahaman Abdulla (CatHaxor)**

Developer of MediBond BD.

**A Nethivo Product**

| Platform | Profile |
|---|---|
| GitHub | [@cathaxor](https://github.com/cathaxor) |
| Instagram | [@abdulla_trzz](https://www.instagram.com/abdulla_trzz/) |
| YouTube | Abdulla Tech 49 |

---

## 🤝 Contributions

Issues, suggestions, bug reports, and contributions are welcome.

To contribute:

1. Fork the repository.
2. Create a feature branch.
3. Make and test your changes.
4. Open a pull request with a clear description.

Do not include real patient records, personal health information, credentials, or private backup files in issues or pull requests.

### ❤️ Built with Flutter

**MediBond BD — Your Medicine. Your Schedule. Your Family.**

Developed by **Abdur Rahaman Abdulla (CatHaxor)**.

**© 2026 Nethivo.**
