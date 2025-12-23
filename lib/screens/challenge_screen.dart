import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
import '../providers/challenges_provider.dart';
import '../core/network/api_client.dart';
import '../core/network/websocket_service.dart';
import '../core/models/models.dart';
import 'lesson_screen.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  final String challengeId;

  const ChallengeScreen({super.key, required this.challengeId});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  late CodeController _codeController;
  String _selectedLanguage = 'python';
  bool _isSubmitting = false;
  Submission? _lastSubmission;
  final _wsService = WebSocketService();
  int _attempts = 0;
  String? _nextChallengeId;
  bool _loadingNext = false;
  String? _currentLessonId;
  String? _nextLessonModuleId;
  String? _nextLessonSlug;
  bool _loadingNextLesson = false;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '# Напишіть ваш код тут\n',
      language: python,
    );
    _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    final token = await ApiClient().getAccessToken();
    if (token != null) {
      await _wsService.connect(token);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    if (_lastSubmission != null) {
      _wsService.unsubscribeFromSubmission(_lastSubmission!.id);
    }
    super.dispose();
  }

  Future<void> _submitCode(Challenge challenge) async {
    if (_codeController.text.trim().isEmpty) {
      _showSnackBar('⚠️ Введіть код', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiClient().createSubmission(
        challengeId: widget.challengeId,
        code: _codeController.text,
        language: _selectedLanguage,
      );

      final submission = Submission.fromJson(response.data);
      setState(() => _lastSubmission = submission);

      _attempts += 1;

      _showSnackBar('✅ Код відправлено на перевірку!', Colors.green);

      // Subscribe to WebSocket updates
      _wsService.subscribeToSubmission(submission.id, (data) {
        _handleSubmissionUpdate(data);
      });
    } catch (e) {
      _showSnackBar('❌ Помилка: $e', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _handleSubmissionUpdate(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == 'testResult' || type == 'test-result') {
      // Individual test result
      final testIndex = (data['testIndex'] as int?) ?? -1;
      final result = (data['result'] is Map)
          ? (data['result'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final passed = (result['passed'] as bool?) ?? false;
      
      _showSnackBar(
        testIndex >= 0
            ? '🧪 Тест ${testIndex + 1}: ${passed ? '✅ Пройдено' : '❌ Не пройдено'}'
            : '🧪 Тест: ${passed ? '✅ Пройдено' : '❌ Не пройдено'}',
        passed ? Colors.green : Colors.orange,
      );
    } else {
      // Full submission update
      final status = data['status']?.toString() ?? 'RUNNING';
      final message = data['message']?.toString();
      
      setState(() {
        _lastSubmission = _lastSubmission?.copyWith(
          status: status,
          score: (data['score'] is num) ? (data['score'] as num).toInt() : null,
        );
      });

      if (status == 'SUCCESS') {
        _showSnackBar('🎉 $message', Colors.green);
        _loadNextChallenge();
      } else if (status == 'FAILED') {
        _showSnackBar('⚠️ $message', Colors.orange);
      } else if (status == 'ERROR') {
        _showSnackBar('❌ $message', Colors.red);
      } else if (status == 'RUNNING') {
        _showSnackBar('⏳ Виконується...', Colors.blue);
      }
    }
  }

  Future<void> _loadNextChallenge() async {
    if (_loadingNext || _nextChallengeId != null || _nextLessonSlug != null) return;

    setState(() {
      _loadingNext = true;
    });

    try {
      final resp = await ApiClient().getNextChallenge(widget.challengeId);
      final next = resp.data;
      if (!mounted) return;

      if (next == null) {
        setState(() {
          _nextChallengeId = null;
        });

        await _loadNextLesson();
        return;
      }

      final map = (next as Map).cast<String, dynamic>();
      final nextId = map['id']?.toString();
      setState(() {
        _nextChallengeId = (nextId != null && nextId.isNotEmpty) ? nextId : null;
      });
    } catch (_) {
      // Best-effort: don't block UX.
    } finally {
      if (mounted) {
        setState(() {
          _loadingNext = false;
        });
      }
    }
  }

  Future<void> _loadNextLesson() async {
    final lessonId = _currentLessonId;
    if (lessonId == null || lessonId.isEmpty) return;
    if (_loadingNextLesson || _nextLessonSlug != null) return;

    setState(() {
      _loadingNextLesson = true;
    });

    try {
      final resp = await ApiClient().getNextLesson(lessonId);
      final next = resp.data;

      if (!mounted) return;

      if (next == null) {
        setState(() {
          _nextLessonModuleId = null;
          _nextLessonSlug = null;
        });
        return;
      }

      final map = (next as Map).cast<String, dynamic>();
      final moduleId = map['moduleId']?.toString();
      final slug = map['slug']?.toString();
      setState(() {
        _nextLessonModuleId = (moduleId != null && moduleId.isNotEmpty) ? moduleId : null;
        _nextLessonSlug = (slug != null && slug.isNotEmpty) ? slug : null;
      });
    } catch (_) {
      // Best-effort.
    } finally {
      if (mounted) {
        setState(() {
          _loadingNextLesson = false;
        });
      }
    }
  }

  void _goNextOrBack() {
    final nextId = _nextChallengeId;
    if (nextId != null && nextId.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChallengeScreen(challengeId: nextId)),
      );
      return;
    }

    final moduleId = _nextLessonModuleId;
    final lessonSlug = _nextLessonSlug;
    if (moduleId != null && moduleId.isNotEmpty && lessonSlug != null && lessonSlug.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LessonScreen(moduleId: moduleId, lessonSlug: lessonSlug),
        ),
      );
      return;
    }

    Navigator.pop(context);
  }

  Future<void> _getHint(Challenge challenge) async {
    setState(() => _isSubmitting = true);

    try {
      final response = await ApiClient().getHint(
        challengeId: widget.challengeId,
        userCode: _codeController.text,
        failingOutput: _lastSubmission?.errorMessage,
        attempts: _attempts + 1,
        locale: 'uk',
      );

      final hint = (response.data as Map)['hintText']?.toString() ?? '';

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text('Підказка від AI'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(hint),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрити'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnackBar('❌ Помилка отримання підказки: $e', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(challengeProvider(widget.challengeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Завдання'),
        elevation: 0,
        actions: [
          if (_lastSubmission != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: _buildStatusChip(_lastSubmission!.status),
              ),
            ),
        ],
      ),
      body: challengeAsync.when(
        data: (challenge) => _buildChallengeView(challenge),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Помилка: $error')),
      ),
    );
  }

  Widget _buildChallengeView(Challenge challenge) {
    final isSuccess = _lastSubmission?.status == 'SUCCESS';
    _currentLessonId = challenge.lessonId;

    return Column(
      children: [
        // Description section
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.grey.shade50,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildDifficultyBadge(challenge.difficulty),
                  const SizedBox(height: 16),
                  Text(
                    challenge.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 20, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text('${challenge.xpReward} XP'),
                      const SizedBox(width: 16),
                      Icon(Icons.timer, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${challenge.timeLimit}s'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const Divider(height: 1),

        // Code editor section
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Language selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    const Text('Мова:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedLanguage,
                      items: const [
                        DropdownMenuItem(value: 'python', child: Text('Python')),
                        DropdownMenuItem(value: 'javascript', child: Text('JavaScript')),
                        DropdownMenuItem(value: 'java', child: Text('Java')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLanguage = value);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Code editor
              Expanded(
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: _codeController,
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: isSuccess
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _goNextOrBack,
                          icon: (_loadingNext || _loadingNextLesson)
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _nextChallengeId != null || _nextLessonSlug != null
                                      ? Icons.arrow_forward
                                      : Icons.arrow_back,
                                ),
                          label: Text(
                            (_loadingNext || _loadingNextLesson)
                                ? 'Перевіряємо наступне…'
                                : (_nextChallengeId != null
                                    ? 'Наступне завдання'
                                    : (_nextLessonSlug != null ? 'Наступний урок' : 'Назад до уроку')),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : () => _getHint(challenge),
                              icon: const Icon(Icons.lightbulb_outline),
                              label: const Text('Підказка AI'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : () => _submitCode(challenge),
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.play_arrow),
                              label: Text(_isSubmitting ? 'Виконання...' : 'Запустити'),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    String text;

    switch (difficulty.toUpperCase()) {
      case 'EASY':
        color = Colors.green;
        text = 'Легко';
        break;
      case 'MEDIUM':
        color = Colors.orange;
        text = 'Середньо';
        break;
      case 'HARD':
        color = Colors.red;
        text = 'Складно';
        break;
      default:
        color = Colors.grey;
        text = difficulty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'PENDING':
        color = Colors.grey;
        text = 'Очікування';
        icon = Icons.schedule;
        break;
      case 'RUNNING':
        color = Colors.blue;
        text = 'Виконується';
        icon = Icons.refresh;
        break;
      case 'SUCCESS':
        color = Colors.green;
        text = 'Успіх';
        icon = Icons.check_circle;
        break;
      case 'FAILED':
        color = Colors.orange;
        text = 'Не пройдено';
        icon = Icons.warning;
        break;
      case 'ERROR':
        color = Colors.red;
        text = 'Помилка';
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
