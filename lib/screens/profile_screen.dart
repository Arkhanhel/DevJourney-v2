import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/progress_service.dart';
import '../core/network/api_client.dart';
import '../core/models/models.dart' as core_models;
import '../models/models.dart' as app_models;
import 'auth/login_screen.dart';
import 'achievements_screen.dart';

final profileUserProvider = FutureProvider<core_models.User>((ref) async {
  final api = ApiClient();
  final userData = await api.getCurrentUser();
  return core_models.User.fromJson(userData.data as Map<String, dynamic>);
});

final profileProgressProvider = FutureProvider<app_models.UserProgress>((ref) async {
  final progressService = ProgressService(ApiClient());
  return progressService.getUserProgress();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(profileUserProvider);
    final progressAsync = ref.watch(profileProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профіль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Вийти'),
                  content: const Text('Ви впевнені, що хочете вийти?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Скасувати'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Вийти'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                await ref.read(authProvider.notifier).logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileUserProvider);
          ref.invalidate(profileProgressProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // User Info Header
              userAsync.when(
                data: (user) => _buildUserHeader(user),
                loading: () => const _LoadingHeader(),
                error: (error, stack) => _ErrorHeader(error: error),
              ),

              const SizedBox(height: 16),

              // Progress Stats
              progressAsync.when(
                data: (progress) => _buildProgressSection(context, progress),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Помилка завантаження прогресу: $error'),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Settings Section
              userAsync.maybeWhen(
                data: (user) => _buildSettingsSection(context, ref, user),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPersonalizationDialog(
    BuildContext context,
    WidgetRef ref,
    core_models.User user,
  ) async {
    final profile = user.profile;
    final ageController = TextEditingController(
      text: profile?.age?.toString() ?? '',
    );
    final interestsController = TextEditingController(
      text: profile?.interests.join(', ') ?? '',
    );
    final goalsController = TextEditingController(
      text: profile?.learningGoals ?? '',
    );
    String skillLevel = profile?.skillLevel ?? 'BEGINNER';
    String preferredLanguage = profile?.preferredLanguage ?? 'uk';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Персоналізація навчання'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Вік'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: preferredLanguage,
                  decoration: const InputDecoration(labelText: 'Мова підказок'),
                  items: const [
                    DropdownMenuItem(value: 'uk', child: Text('Українська')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ru', child: Text('Русский')),
                  ],
                  onChanged: (v) => preferredLanguage = v ?? preferredLanguage,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: skillLevel,
                  decoration: const InputDecoration(labelText: 'Рівень навичок'),
                  items: const [
                    DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                    DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                    DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                  ],
                  onChanged: (v) => skillLevel = v ?? skillLevel,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: interestsController,
                  decoration: const InputDecoration(
                    labelText: 'Інтереси (через кому)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: goalsController,
                  decoration: const InputDecoration(
                    labelText: 'Цілі навчання',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () async {
                final age = int.tryParse(ageController.text.trim());
                final interests = interestsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                try {
                  await ApiClient().updateUserProfile(
                    age: age,
                    interests: interests,
                    preferredLanguage: preferredLanguage,
                    skillLevel: skillLevel,
                    learningGoals: goalsController.text.trim().isEmpty
                        ? null
                        : goalsController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ref.invalidate(profileUserProvider);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Не вдалося зберегти: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Зберегти'),
            ),
          ],
        );
      },
    );

    ageController.dispose();
    interestsController.dispose();
    goalsController.dispose();
  }

  Widget _buildUserHeader(core_models.User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: user.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      user.avatarUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            user.username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, app_models.UserProgress progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статистика',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Очки',
                  progress.totalPoints.toString(),
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Виклики',
                  progress.completedChallenges.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Поточна серія',
                  '${progress.currentStreak} днів',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Рекорд',
                  '${progress.longestStreak} днів',
                  Icons.emoji_events,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Achievements Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AchievementsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.emoji_events),
              label: const Text('Досягнення'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref, core_models.User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Налаштування',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Редагувати профіль'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showPersonalizationDialog(context, ref, user);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Змінити пароль'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to change password
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Сповіщення'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to notifications settings
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Про додаток'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'DevJourney',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2024 DevJourney',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: CircularProgressIndicator(),
          ),
          SizedBox(height: 16),
          Text(
            'Завантаження...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorHeader extends StatelessWidget {
  final Object error;

  const _ErrorHeader({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.red[100],
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Помилка: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}
