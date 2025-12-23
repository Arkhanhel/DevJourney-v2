import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import 'challenge_screen.dart';

class LessonScreen extends StatefulWidget {
  final String moduleId;
  final String lessonSlug;
  final String? lessonTitle;

  const LessonScreen({
    super.key,
    required this.moduleId,
    required this.lessonSlug,
    this.lessonTitle,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _lesson;
  bool _nextLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await ApiClient().getLesson(widget.moduleId, widget.lessonSlug);
      final data = (resp.data as Map).cast<String, dynamic>();
      setState(() {
        _lesson = data;
        _loading = false;
      });

      final lessonId = _lesson?['id']?.toString();
      if (lessonId != null && lessonId.isNotEmpty) {
        // Best-effort: ignore errors, UI still works.
        await ApiClient().updateLessonProgress(lessonId, 'STARTED');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _completeAndNext() async {
    final lessonId = _lesson?['id']?.toString();
    if (lessonId == null || lessonId.isEmpty) return;

    setState(() {
      _nextLoading = true;
    });

    try {
      await ApiClient().updateLessonProgress(lessonId, 'COMPLETED');
      final resp = await ApiClient().getNextLesson(lessonId);
      final next = resp.data;

      if (!mounted) return;

      if (next == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Це був останній урок у курсі.')),
        );
        return;
      }

      final nextMap = (next as Map).cast<String, dynamic>();
      final nextModuleId = nextMap['moduleId']?.toString();
      final nextSlug = nextMap['slug']?.toString();

      if (nextModuleId == null || nextSlug == null || nextModuleId.isEmpty || nextSlug.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося відкрити наступний урок.')),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LessonScreen(
            moduleId: nextModuleId,
            lessonSlug: nextSlug,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _nextLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.lessonTitle ?? _lesson?['title']?.toString() ?? 'Урок';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _LessonView(
                    lesson: _lesson!,
                    nextLoading: _nextLoading,
                    onCompleteAndNext: _completeAndNext,
                  ),
                ),
    );
  }
}

class _LessonView extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final bool nextLoading;
  final VoidCallback onCompleteAndNext;

  const _LessonView({
    required this.lesson,
    required this.nextLoading,
    required this.onCompleteAndNext,
  });

  @override
  Widget build(BuildContext context) {
    final content = lesson['content']?.toString() ?? '';
    final challenges = (lesson['challenges'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (content.trim().isNotEmpty) ...[
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'Завдання',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (challenges.isEmpty)
          const Text('У цьому уроці поки що немає завдань.')
        else
          ...challenges.map((c) => _ChallengeTile(challenge: c)),

        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: nextLoading ? null : onCompleteAndNext,
          icon: nextLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward),
          label: Text(nextLoading ? 'Переходимо…' : 'Завершити урок і далі'),
        ),
      ],
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  final Map<String, dynamic> challenge;

  const _ChallengeTile({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final id = challenge['id']?.toString() ?? '';
    final title = challenge['title']?.toString() ?? 'Challenge';
    final difficulty = challenge['difficulty']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.code),
        title: Text(title),
        subtitle: difficulty.isNotEmpty ? Text('Складність: $difficulty') : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: id.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChallengeScreen(challengeId: id),
                  ),
                );
              },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Спробувати знову'),
            ),
          ],
        ),
      ),
    );
  }
}
