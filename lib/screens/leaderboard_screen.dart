import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/challenges_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider(20));

    return Scaffold(
      appBar: AppBar(title: const Text('Таблиця лідерів')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaderboardProvider(20));
          await ref.read(leaderboardProvider(20).future);
        },
        child: leaderboardAsync.when(
          data: (rows) {
            if (rows.isEmpty) {
              return const _EmptyState();
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = rows[index];
                final name = (row['username'] ?? row['user'] ?? 'Анонім').toString();
                final rawPoints = row['points'] ?? row['totalPoints'] ?? row['xp'] ?? 0;
                final points = rawPoints is num ? rawPoints.toInt() : 0;
                final streak = row['streak'] ?? row['currentStreak'];
                return _LeaderCard(
                  rank: index + 1,
                  name: name,
                  points: points,
                  streak: streak is int ? streak : null,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorState(
            message: 'Не вдалося завантажити: $err',
            onRetry: () => ref.invalidate(leaderboardProvider(20)),
          ),
        ),
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final int rank;
  final String name;
  final int points;
  final int? streak;

  const _LeaderCard({required this.rank, required this.name, required this.points, this.streak});

  Color _rankColor(int r) {
    switch (r) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.blueGrey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blueGrey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _rankColor(rank);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            '$rank',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: streak != null ? Text('Серія: $streak') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 18),
            const SizedBox(width: 6),
            Text(points.toString()),
          ],
        ),
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
            Icon(Icons.leaderboard, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Таблиця порожня'),
            SizedBox(height: 6),
            Text('Станьте першим, щоб зібрати очки!'),
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
