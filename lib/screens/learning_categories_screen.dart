import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/challenges_provider.dart';
import 'challenge_detail_screen.dart';

class LearningCategoriesScreen extends ConsumerStatefulWidget {
  const LearningCategoriesScreen({super.key});

  @override
  ConsumerState<LearningCategoriesScreen> createState() => _LearningCategoriesScreenState();
}

class _LearningCategoriesScreenState extends ConsumerState<LearningCategoriesScreen> {
  String _query = '';
  final Set<String> _selectedDifficulties = {'easy', 'medium', 'hard'};

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(challengesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Категорії навчання'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(challengesListProvider);
            await ref.read(challengesListProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSearch(),
              const SizedBox(height: 12),
              _buildDifficultyFilters(),
              const SizedBox(height: 12),
              _buildCatalog(challengesAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalog(AsyncValue<List<Challenge>> challengesAsync) {
    return challengesAsync.when(
      data: (challenges) {
        final filtered = _applyFilters(challenges);
        if (filtered.isEmpty) {
          return _EmptyState(
            title: 'Нічого не знайдено',
            description: 'Спробуйте змінити фільтри або пошук.',
            onRetry: () => ref.invalidate(challengesListProvider),
          );
        }
        final buckets = _groupByTag(filtered);
        return Column(
          children: buckets.entries
              .map((entry) => _CategorySection(tag: entry.key, challenges: entry.value))
              .toList(),
        );
      },
      loading: () => const _LoadingSkeleton(),
      error: (err, _) => _EmptyState(
        title: 'Помилка завантаження',
        description: '$err',
        onRetry: () => ref.invalidate(challengesListProvider),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Пошук задач або тегів',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
    );
  }

  Widget _buildDifficultyFilters() {
    const diffs = [
      {'key': 'easy', 'label': 'Easy'},
      {'key': 'medium', 'label': 'Medium'},
      {'key': 'hard', 'label': 'Hard'},
    ];
    return Wrap(
      spacing: 8,
      children: diffs.map((diff) {
        final key = diff['key']!;
        final selected = _selectedDifficulties.contains(key);
        return FilterChip(
          label: Text(diff['label']!),
          selected: selected,
          onSelected: (_) {
            setState(() {
              if (selected) {
                _selectedDifficulties.remove(key);
              } else {
                _selectedDifficulties.add(key);
              }
              if (_selectedDifficulties.isEmpty) {
                _selectedDifficulties.addAll(['easy', 'medium', 'hard']);
              }
            });
          },
        );
      }).toList(),
    );
  }

  List<Challenge> _applyFilters(List<Challenge> challenges) {
    return challenges.where((c) {
      final matchesQuery = _query.isEmpty ||
          c.title.toLowerCase().contains(_query) ||
          c.description.toLowerCase().contains(_query) ||
          c.tags.any((t) => t.toLowerCase().contains(_query));
      final matchesDiff = _selectedDifficulties.contains(c.difficulty.toLowerCase());
      return matchesQuery && matchesDiff;
    }).toList();
  }

  Map<String, List<Challenge>> _groupByTag(List<Challenge> challenges) {
    final map = <String, List<Challenge>>{};
    for (final c in challenges) {
      final tags = c.tags.isEmpty ? ['Загальні'] : c.tags;
      for (final tag in tags) {
        final key = tag.trim();
        map.putIfAbsent(key, () => []).add(c);
      }
    }
    return map;
  }
}

class _CategorySection extends StatelessWidget {
  final String tag;
  final List<Challenge> challenges;

  const _CategorySection({required this.tag, required this.challenges});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.label_important, size: 18, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                tag,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: challenges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return _ChallengeCard(challenge: challenge);
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeCard({required this.challenge});

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return Colors.green.shade200;
      case 'medium':
        return Colors.orange.shade200;
      case 'hard':
        return Colors.red.shade200;
      default:
        return Colors.blue.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChallengeDetailScreen(challengeId: challenge.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _difficultyColor(challenge.difficulty),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(challenge.difficulty.toUpperCase()),
                    ),
                    const Spacer(),
                    Text('${challenge.totalTests} тестів', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  challenge.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  challenge.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                const Spacer(),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: challenge.tags
                      .take(3)
                      .map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) => index)
          .map(
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 160,
                    height: 16,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, __) => Container(
                        width: 240,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onRetry;

  const _EmptyState({required this.title, required this.description, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Спробувати знову'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
