import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/challenges_service.dart';
import '../core/network/api_client.dart';
import '../core/network/websocket_service.dart';

class ChallengeExecutionScreen extends ConsumerStatefulWidget {
  final Challenge challenge;

  const ChallengeExecutionScreen({super.key, required this.challenge});

  @override
  ConsumerState<ChallengeExecutionScreen> createState() =>
      _ChallengeExecutionScreenState();
}

class _ChallengeExecutionScreenState
    extends ConsumerState<ChallengeExecutionScreen> {
  late TextEditingController _codeController;
  String _selectedLanguage = 'javascript';
  bool _isSubmitting = false;
  Submission? _lastSubmission;
  bool _isHintLoading = false;
  String? _lastHint;
  int _attempts = 0;
  int? _profileAge;
  String? _profileSkillLevel;
  List<String>? _profileInterests;
  String? _profilePreferredLanguage;
  String? _submissionStatus;
  String? _submissionMessage;
  int? _submissionScore;
  int? _submissionPassed;
  int? _submissionTotal;
  double? _submissionTotalTime;
  String? _submissionError;
  String? _subscribedSubmissionId;

  final Map<String, String> _codeTemplates = {
    'javascript': '''function solution() {
  // Ваш код тут
  return result;
}''',
    'python': '''def solution():
    # Ваш код тут
    return result''',
    'java': '''public class Solution {
    public static Object solution() {
        // Ваш код тут
        return result;
    }
}''',
  };

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: _codeTemplates[_selectedLanguage],
    );
    _loadProfileMeta();
  }

  @override
  void dispose() {
    if (_subscribedSubmissionId != null) {
      WebSocketService().unsubscribeFromSubmission(_subscribedSubmissionId!);
    }
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileMeta() async {
    try {
      final resp = await ApiClient().getCurrentUser();
      final data = resp.data as Map<String, dynamic>;
      final profile = data['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        setState(() {
          _profileAge = profile['age'] as int?;
          _profileSkillLevel = profile['skillLevel'] as String?;
          _profileInterests = (profile['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList();
          _profilePreferredLanguage =
              profile['preferredLanguage'] as String?;
        });
      }
    } catch (_) {
      // Non-blocking: hint works even without profile meta
    }
  }

  Future<void> _submitCode() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Будь ласка, напишіть код')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ChallengesService(ApiClient());
      final submission = await service.submitCode(
        challengeId: widget.challenge.id,
        code: _codeController.text,
        language: _selectedLanguage,
      );

      setState(() {
        _lastSubmission = submission;
        _isSubmitting = false;
        _submissionStatus = submission.status;
        _submissionMessage = null;
        _submissionScore = submission.score;
        _submissionError = submission.errorMessage;
        _submissionPassed = null;
        _submissionTotal = null;
        _submissionTotalTime = null;
      });

      _attempts += 1;

      await _subscribeToSubmissionUpdates(submission.id);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e')),
      );
    }
  }

  Future<void> _subscribeToSubmissionUpdates(String submissionId) async {
    try {
      if (_subscribedSubmissionId != null && _subscribedSubmissionId != submissionId) {
        WebSocketService().unsubscribeFromSubmission(_subscribedSubmissionId!);
      }

      _subscribedSubmissionId = submissionId;

      final token = await ApiClient().getAccessToken();
      if (token == null) {
        return;
      }

      await WebSocketService().connect(token);

      WebSocketService().subscribeToSubmission(submissionId, (payload) {
        if (!mounted) return;

        final type = payload['type']?.toString();
        if (type == 'test-result') {
          // Optional: show per-test progress later
          return;
        }

        final status = payload['status']?.toString();
        setState(() {
          _submissionStatus = status ?? _submissionStatus;
          _submissionMessage = payload['message']?.toString() ?? _submissionMessage;
          _submissionScore = (payload['score'] is num) ? (payload['score'] as num).toInt() : _submissionScore;
          _submissionPassed = (payload['passed'] is num) ? (payload['passed'] as num).toInt() : _submissionPassed;
          _submissionTotal = (payload['total'] is num) ? (payload['total'] as num).toInt() : _submissionTotal;
          _submissionTotalTime = (payload['totalTime'] is num) ? (payload['totalTime'] as num).toDouble() : _submissionTotalTime;
          _submissionError = payload['error']?.toString() ?? _submissionError;
        });

        if (status == null) return;

        final upper = status.toUpperCase();
        if (upper == 'SUCCESS' || upper == 'FAILED' || upper == 'ERROR') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_submissionMessage ?? 'Результат: $upper')),
          );
          WebSocketService().unsubscribeFromSubmission(submissionId);
        }
      });
    } catch (_) {
      // Non-blocking: user can still poll status via /submissions/:id/status
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Вітаємо!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ви успішно виконали виклик!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_lastSubmission?.score != null)
              Text(
                'Ваш бал: ${_lastSubmission!.score}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to challenge list
            },
            child: const Text('Закрити'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(Submission submission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Помилка виконання'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Статус: ${submission.status}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (submission.errorMessage != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Повідомлення:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    submission.errorMessage!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Спробувати знову'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestHint() async {
    setState(() {
      _isHintLoading = true;
    });

    try {
      final response = await ApiClient().getHint(
        challengeId: widget.challenge.id,
        userCode: _codeController.text,
        failingOutput: _lastSubmission?.errorMessage,
        attempts: _attempts + 1,
        locale: _profilePreferredLanguage ?? 'uk',
      );

      final data = response.data as Map<String, dynamic>;
      setState(() {
        _lastHint = data['hintText'] as String? ?? data['explanation'] as String?;
        _isHintLoading = false;
      });
    } catch (e) {
      setState(() => _isHintLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не вдалося отримати підказку: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challenge.title),
        actions: [
          IconButton(
            tooltip: 'Підказка AI',
            icon: _isHintLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology),
            onPressed: _isHintLoading ? null : _requestHint,
          ),
          // Language Selector
          PopupMenuButton<String>(
            initialValue: _selectedLanguage,
            onSelected: (language) {
              setState(() {
                _selectedLanguage = language;
                _codeController.text = _codeTemplates[language]!;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'javascript',
                child: Text('JavaScript'),
              ),
              const PopupMenuItem(
                value: 'python',
                child: Text('Python'),
              ),
              const PopupMenuItem(
                value: 'java',
                child: Text('Java'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedLanguage.toUpperCase()),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Challenge Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.challenge.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Тестів: ${widget.challenge.totalTests}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (_submissionStatus != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatusPill(status: _submissionStatus!),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _submissionMessage ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  if (_submissionScore != null || _submissionPassed != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (_submissionScore != null)
                          Text('Score: $_submissionScore%', style: const TextStyle(fontSize: 12)),
                        if (_submissionPassed != null && _submissionTotal != null)
                          Text('Tests: $_submissionPassed/$_submissionTotal', style: const TextStyle(fontSize: 12)),
                        if (_submissionTotalTime != null)
                          Text('Time: ${_submissionTotalTime!.toStringAsFixed(1)}ms', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                  if (_submissionError != null && _submissionError!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _submissionError!,
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ],
            ),
          ),

          if (_lastHint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                color: Colors.yellow[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastHint!,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Code Editor
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _codeController,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Напишіть ваш код тут...',
                ),
              ),
            ),
          ),

          // Submit Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitCode,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Відправка...' : 'Відправити код'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final upper = status.toUpperCase();
    Color color;
    String label;
    switch (upper) {
      case 'PENDING':
        color = Colors.grey;
        label = 'Очікує';
        break;
      case 'RUNNING':
        color = Colors.blue;
        label = 'Виконується';
        break;
      case 'SUCCESS':
        color = Colors.green;
        label = 'Успіх';
        break;
      case 'FAILED':
        color = Colors.orange;
        label = 'Не пройдено';
        break;
      case 'ERROR':
        color = Colors.red;
        label = 'Помилка';
        break;
      default:
        color = Colors.grey;
        label = upper;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
