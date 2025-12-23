import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/challenges_provider.dart';
import '../core/models/models.dart';
import 'challenge_screen.dart';

class MySubmissionsScreen extends ConsumerWidget {
  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(mySubmissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мої відправки')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mySubmissionsProvider);
          await ref.read(mySubmissionsProvider.future);
        },
        child: submissionsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const _EmptyState();
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final submission = items[index];
                return _SubmissionCard(submission: submission);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorState(
            message: 'Помилка завантаження: $err',
            onRetry: () => ref.invalidate(mySubmissionsProvider),
          ),
        ),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final Submission submission;

  const _SubmissionCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusChip(status: submission.status),
                const Spacer(),
                Text(
                  _formatDate(submission.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Завдання: ${submission.challengeId}',
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.code, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(submission.language.toUpperCase()),
                const SizedBox(width: 12),
                if (submission.score != null)
                  Row(
                    children: [
                      Icon(Icons.stars, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text('${submission.score} балів'),
                    ],
                  ),
              ],
            ),
            if (submission.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                submission.errorMessage!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChallengeScreen(challengeId: submission.challengeId),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Відкрити задачу'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
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
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Поки що немає відправок'),
            SizedBox(height: 6),
            Text('Запустіть перше рішення, щоб побачити історію.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
