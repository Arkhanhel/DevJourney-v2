# DevJourney Flutter App

Мобільний та веб-застосунок для навчання програмування з AI-підказками.

## 🚀 Можливості

- ✅ **Автентифікація** - JWT-based логін/реєстрація
- ✅ **Треки навчання** - Web Development, Python, та інші
- ✅ **Курси** - Структуровані модулі з уроками
- ✅ **Завдання** - Code challenges з різними рівнями складності
- ✅ **Code Editor** - Вбудований редактор коду з підсвічуванням синтаксису
- ✅ **AI Підказки** - Персоналізовані підказки від AI асистента
- ✅ **XP System** - Gamification з нагородами та leaderboard
- 🔄 **Real-time** - WebSocket оновлення статусу виконання (в розробці)

## 📦 Встановлення

### Вимоги
- Flutter 3.2.0+
- Dart 3.0+
- Android Studio / VS Code
- Backend запущений на `http://localhost:3001`

### Встановлення залежностей

\`\`\`bash
cd flutter_app
flutter pub get
\`\`\`

## 🏃 Запуск

### Web
\`\`\`bash
flutter run -d chrome
\`\`\`

### Android/iOS
\`\`\`bash
# Підключіть пристрій або запустіть емулятор
flutter run
\`\`\`

### Налаштування API URL

Змініть `baseUrl` в `lib/core/config/api_config.dart`:

\`\`\`dart
// Для фізичного пристрою використовуйте IP машини:
static const String baseUrl = 'http://192.168.1.100:3001/api';

// Для емулятора:
static const String baseUrl = 'http://10.0.2.2:3001/api'; // Android
static const String baseUrl = 'http://localhost:3001/api'; // iOS/Web
\`\`\`

## 🔑 Демо-акаунт

```
Email: demo@devjourney.com
Password: password123
```

## 📁 Структура проекту

\`\`\`
lib/
├── core/
│   ├── config/         # Конфігурація API
│   ├── models/         # Data models (User, Track, Course, Challenge)
│   └── network/        # API client + Auth interceptor
├── providers/          # Riverpod state management
│   ├── auth_provider.dart
│   ├── tracks_provider.dart
│   └── challenges_provider.dart
├── screens/            # UI екрани
│   ├── auth/
│   │   └── login_screen.dart
│   ├── home_screen.dart
│   ├── tracks_screen.dart
│   ├── courses_screen.dart
│   ├── course_details_screen.dart
│   └── challenge_screen.dart
└── main.dart
\`\`\`

## 🎨 Основні екрани

### 1. Login Screen
- Email/password авторизація
- Автоматичний refresh token
- Показ demo credentials

### 2. Home Screen
- Привітання з username
- Показ XP користувача
- Прогрес по завданням
- Кнопка переходу до треків

### 3. Tracks Screen
- Список доступних треків
- Icons для кожного треку
- Навігація до курсів

### 4. Courses Screen
- Курси вибраного треку
- Level badges (Початковий/Середній/Просунутий)
- Thumbnail images
- Duration info

### 5. Course Details Screen
- Опис курсу
- Кнопка "Розпочати курс"
- Список модулів з уроками
- Expandable lessons з challenges

### 6. Challenge Screen (🔥 Головний)
- Опис завдання
- Difficulty badge
- XP reward
- **Code Editor** з syntax highlighting
- Вибір мови програмування
- Кнопка "Запустити код"
- Кнопка "Підказка AI"
- Real-time статус виконання (PENDING → RUNNING → SUCCESS/FAILED)
- Polling для оновлення статусу

## 🛠 Технології

- **Flutter 3.2** - UI framework
- **Riverpod 2.4** - State management
- **Dio 5.4** - HTTP client
- **flutter_secure_storage** - Secure token storage
- **code_text_field** - Code editor widget
- **highlight** - Syntax highlighting

## 🔐 Безпека

- JWT tokens зберігаються в Secure Storage
- Автоматичний refresh token на 401
- HTTPS підтримка (для production)

## 🚧 TODO

- [ ] WebSocket integration для real-time updates
- [ ] Onboarding flow (вік, інтереси, skill level)
- [ ] Profile screen
- [ ] Submissions history
- [ ] Leaderboard screen
- [ ] Dark mode
- [ ] Offline mode з caching
- [ ] Push notifications

## 📝 Примітки

- **Code Editor** поки підтримує тільки Python highlighting (можна додати інші з пакету `highlight`)
- **WebSocket** ready на backend, треба додати `socket_io_client` і підключити
- **Тести** ще не написані

## 🔗 API Endpoints

Всі endpoints документовані в Swagger: `http://localhost:3001/api/docs`

- `POST /auth/login` - Login
- `GET /auth/me` - Current user
- `GET /tracks` - All tracks
- `GET /courses` - Courses by track
- `GET /challenges/:id` - Challenge details
- `POST /submissions` - Submit code
- `GET /submissions/:id` - Submission status
- `POST /ai/hint` - Get AI hint
- `GET /progress` - User progress

## 📱 Платформи

- ✅ Android
- ✅ iOS
- ✅ Web
- ❌ Desktop (не тестувалось)
