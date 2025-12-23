import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/progress_service.dart';
import '../core/network/api_client.dart';

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final service = ProgressService(ApiClient());
  return service.getAchievements();
});

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Досягнення'),
      ),
      body: achievementsAsync.when(
        data: (achievements) {
          final unlockedAchievements =
              achievements.where((a) => a.unlocked).toList();
          final lockedAchievements =
              achievements.where((a) => !a.unlocked).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(achievementsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Progress Summary
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Прогрес',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${unlockedAchievements.length}/${achievements.length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: achievements.isEmpty
                              ? 0
                              : unlockedAchievements.length /
                                  achievements.length,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Unlocked Achievements
                if (unlockedAchievements.isNotEmpty) ...[
                  const Text(
                    'Відкриті досягнення',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...unlockedAchievements.map((achievement) {
                    return _buildAchievementCard(achievement, true);
                  }),
                  const SizedBox(height: 24),
                ],

                // Locked Achievements
                if (lockedAchievements.isNotEmpty) ...[
                  const Text(
                    'Заблоковані досягнення',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...lockedAchievements.map((achievement) {
                    return _buildAchievementCard(achievement, false);
                  }),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Помилка: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(achievementsProvider);
                },
                child: const Text('Спробувати знову'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUnlocked ? null : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.amber : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? Icons.emoji_events : Icons.lock,
                size: 32,
                color: isUnlocked ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? null : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnlocked ? Colors.grey[700] : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: isUnlocked ? Colors.amber : Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${achievement.pointsRequired} очок',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked ? null : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (isUnlocked && achievement.unlockedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Відкрито: ${_formatDate(achievement.unlockedAt!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Badge
            if (isUnlocked)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
