# 🚀 СЛЕДУЮЩИЕ ШАГИ - DevJourney

## КРИТИЧЕСКИЕ ЗАДАЧИ (следующая сессия)

### 1. WebSocket Gateway для Real-Time (1-2 часа)

**Файл:** `backend/src/events/events.gateway.ts`

```typescript
import { 
  WebSocketGateway, 
  WebSocketServer, 
  SubscribeMessage, 
  MessageBody, 
  ConnectedSocket 
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: 'submissions'
})
export class EventsGateway {
  @WebSocketServer()
  server: Server;

  @SubscribeMessage('subscribe')
  handleSubscribe(
    @MessageBody() data: { submissionId: string },
    @ConnectedSocket() client: Socket
  ) {
    client.join(`submission:${data.submissionId}`);
    return { subscribed: true };
  }

  emitSubmissionUpdate(submissionId: string, data: any) {
    this.server.to(`submission:${submissionId}`).emit('update', data);
  }
}
```

**Подключить в:** `app.module.ts`

---

### 2. Обновить Execution Processor (1 час)

**Файл:** `backend/src/runner/execution.processor.ts`

**Заменить старый RunnerService на новый:**

```typescript
import { RunnerService } from './runner-new.service'; // Используй новый!

@Processor('grading')
export class ExecutionProcessor {
  constructor(
    private runnerService: RunnerService,
    private prisma: PrismaService,
    private eventsGateway: EventsGateway, // Добавь WebSocket
  ) {}

  @Process()
  async handleExecution(job: Job) {
    const { submissionId, challengeId, code, language } = job.data;

    // Обновить статус -> RUNNING
    await this.prisma.submission.update({
      where: { id: submissionId },
      data: { status: 'RUNNING' }
    });
    this.eventsGateway.emitSubmissionUpdate(submissionId, { status: 'RUNNING' });

    // Получить тесты
    const testCases = await this.prisma.testCase.findMany({
      where: { challengeId }
    });

    // Выполнить с новым Runner
    const result = await this.runnerService.executeWithTests(
      code,
      language,
      testCases.map(t => ({ input: t.input, expected: t.expected })),
      5000,
      256
    );

    // Рассчитать score
    const score = result.allPassed ? 100 : 
      Math.round((result.results.filter(r => r.passed).length / result.results.length) * 100);

    // Обновить submission
    await this.prisma.submission.update({
      where: { id: submissionId },
      data: {
        status: result.allPassed ? 'SUCCESS' : 'FAILED',
        score,
        executionTime: result.totalTime,
        testResults: result.results
      }
    });

    // Отправить через WebSocket
    this.eventsGateway.emitSubmissionUpdate(submissionId, {
      status: result.allPassed ? 'SUCCESS' : 'FAILED',
      score,
      testResults: result.results
    });

    // Начислить XP если успешно
    if (result.allPassed) {
      const challenge = await this.prisma.challenge.findUnique({
        where: { id: challengeId },
        select: { xpReward: true }
      });

      const submission = await this.prisma.submission.findUnique({
        where: { id: submissionId },
        select: { userId: true }
      });

      await this.prisma.xpEvent.create({
        data: {
          userId: submission.userId,
          amount: challenge.xpReward,
          reason: 'challenge_completed',
          metadata: { challengeId, submissionId }
        }
      });

      await this.prisma.user.update({
        where: { id: submission.userId },
        data: { totalXp: { increment: challenge.xpReward } }
      });
    }
  }
}
```

---

### 3. Установить WebSocket пакеты

```bash
cd backend
npm install @nestjs/websockets @nestjs/platform-socket.io socket.io
```

---

## FLUTTER FRONTEND (следующие 2-3 дня)

### Шаг 1: Установить зависимости

**Файл:** `flutter_app/pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  hooks_riverpod: ^2.4.9
  flutter_hooks: ^0.20.3
  
  # Network
  dio: ^5.4.0
  web_socket_channel: ^2.4.0
  
  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  
  # UI
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  
  # Code Editor
  flutter_code_editor: ^0.3.0
  flutter_highlight: ^0.7.0
  highlight: ^0.7.0
  
  # Markdown
  flutter_markdown: ^0.6.18
  
  # Utils
  intl: ^0.18.1
  url_launcher: ^6.2.2
```

```bash
cd flutter_app
flutter pub get
```

---

### Шаг 2: API Client с Dio

**Файл:** `flutter_app/lib/services/api_client.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const String baseUrl = 'http://localhost:3001'; // Измени для production

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 30),
        )),
        _storage = FlutterSecureStorage() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _storage.write(key: 'access_token', value: response.data['accessToken']);
    return response.data;
  }

  // Tracks
  Future<List<dynamic>> getTracks() async {
    final response = await _dio.get('/tracks');
    return response.data;
  }

  // Courses
  Future<List<dynamic>> getCourses({String? trackId}) async {
    final response = await _dio.get('/courses', queryParameters: {
      if (trackId != null) 'trackId': trackId,
    });
    return response.data;
  }

  // Challenges
  Future<Map<String, dynamic>> getChallenge(String id) async {
    final response = await _dio.get('/challenges/$id');
    return response.data;
  }

  // Submissions
  Future<Map<String, dynamic>> submitCode({
    required String challengeId,
    required String code,
    required String language,
  }) async {
    final response = await _dio.post('/submissions', data: {
      'challengeId': challengeId,
      'code': code,
      'language': language,
    });
    return response.data;
  }

  // AI Hints
  Future<Map<String, dynamic>> getHint({
    required String challengeId,
    required String code,
    required int attempts,
    String locale = 'uk',
  }) async {
    final response = await _dio.post('/ai/hint', data: {
      'challengeId': challengeId,
      'userCode': code,
      'attempts': attempts,
      'locale': locale,
    });
    return response.data;
  }
}
```

---

### Шаг 3: Onboarding Screen

**Файл:** `flutter_app/lib/screens/onboarding_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: PageView(
        children: [
          // Step 1: Возраст
          OnboardingPage(
            title: 'Скільки тобі років?',
            child: AgeSelector(),
          ),
          
          // Step 2: Интересы
          OnboardingPage(
            title: 'Що тебе цікавить?',
            child: InterestsSelector(),
          ),
          
          // Step 3: Цели
          OnboardingPage(
            title: 'Чого ти хочеш досягти?',
            child: GoalsInput(),
          ),
        ],
      ),
    );
  }
}
```

---

### Шаг 4: Code Editor Screen

**Файл:** `flutter_app/lib/screens/code_editor_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';

class CodeEditorScreen extends StatefulWidget {
  final String challengeId;

  CodeEditorScreen({required this.challengeId});

  @override
  _CodeEditorScreenState createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen> {
  late CodeController _controller;
  String _output = '';
  bool _isRunning = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '# Напиши свій код тут\n',
      language: python,
    );
  }

  Future<void> _runCode() async {
    setState(() {
      _isRunning = true;
      _attempts++;
    });

    // Submit code через API
    final result = await apiClient.submitCode(
      challengeId: widget.challengeId,
      code: _controller.text,
      language: 'python',
    );

    setState(() {
      _output = result['output'] ?? result['error'] ?? '';
      _isRunning = false;
    });
  }

  Future<void> _getHint() async {
    final hint = await apiClient.getHint(
      challengeId: widget.challengeId,
      code: _controller.text,
      attempts: _attempts,
    );

    // Показать hint в диалоге или боковой панели
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Підказка рівня ${hint['level']}'),
        content: SingleChildScrollView(
          child: Text(hint['hintText']),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Зрозуміло!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Редактор коду'),
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb_outline),
            onPressed: _getHint,
            tooltip: 'Підказка від AI',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: CodeTheme(
              data: CodeThemeData(styles: atomOneDarkTheme),
              child: CodeField(
                controller: _controller,
              ),
            ),
          ),
          Container(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.play_arrow),
                  label: Text('Запустити'),
                  onPressed: _isRunning ? null : _runCode,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.check),
                  label: Text('Відправити'),
                  onPressed: _isRunning ? null : _runCode,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black87,
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  _output,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## БЫСТРЫЙ ЗАПУСК

### Terminal 1: Backend
```bash
cd backend
npm run start:dev
```

### Terminal 2: Flutter Web
```bash
cd flutter_app
flutter run -d chrome
```

### Terminal 3: Prisma Studio (опционально)
```bash
cd backend
npx prisma studio
```

---

## ТЕСТИРОВАНИЕ

1. Открой `http://localhost:3001/api` - Swagger документация
2. Войди как `demo@devjourney.com` / `password123`
3. Получи список треков: `GET /tracks`
4. Запроси AI подсказку: `POST /ai/hint`
5. Протестируй submission workflow

---

## ЧТО ДАЛЬШЕ?

После WebSocket + базового Flutter UI:

1. **Локализация** - пакет `flutter_localizations`
2. **Адаптивный дизайн** - responsive_framework
3. **Тестирование** - widget tests, integration tests
4. **CI/CD** - GitHub Actions
5. **Deploy** - Docker Compose production

**Удачи! 🚀**
