# DevJourney Flutter App

Cross-platform educational coding platform built with Flutter.

## Getting Started

### Prerequisites
- Flutter SDK 3.2.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / Xcode (for mobile development)
- Chrome (for web development)

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Configure API endpoint:
   - For development, the app uses `http://localhost:3001/api`
   - For production, set the `API_URL` environment variable

### Running the App

**Web:**
```bash
flutter run -d chrome
```

**Android:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

### Building

**Web:**
```bash
flutter build web
```

**Android APK:**
```bash
flutter build apk
```

**iOS:**
```bash
flutter build ios
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   └── models.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   └── login_screen.dart
│   └── home_screen.dart
├── services/                 # Business logic & API
│   ├── api_service.dart
│   └── auth_service.dart
└── widgets/                  # Reusable components
```

## Features

- 🔐 Authentication (Login/Register)
- 📝 Browse coding challenges
- 💻 Code editor with syntax highlighting
- ⚡ Real-time code execution
- 🤖 AI-powered hints
- 📊 Progress tracking
- 🏆 Leaderboards
