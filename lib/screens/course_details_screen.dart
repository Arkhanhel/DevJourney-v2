import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tracks_provider.dart';
import '../core/network/api_client.dart';
import 'lesson_screen.dart';

class CourseDetailsScreen extends ConsumerWidget {
  final String courseSlug;

  const CourseDetailsScreen({super.key, required this.courseSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseProvider(courseSlug));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Курс'),
        elevation: 0,
      ),
      body: courseAsync.when(
        data: (courseData) => _buildCourseDetails(context, ref, courseData),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, error.toString()),
      ),
    );
  }

  Widget _buildCourseDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> courseData) {
    final course = courseData;
    final modules = courseData['modules'] as List<dynamic>? ?? [];

    Map<String, dynamic>? firstLesson;
    String? firstLessonModuleId;
    if (modules.isNotEmpty) {
      for (final m in modules) {
        if (m is Map) {
          final mm = m.cast<String, dynamic>();
          final lessons = mm['lessons'] as List<dynamic>? ?? const [];
          if (lessons.isNotEmpty) {
            final l = lessons.first;
            if (l is Map) {
              firstLesson = l.cast<String, dynamic>();
              firstLessonModuleId = mm['id']?.toString();
              break;
            }
          }
        }
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (course['title'] as String?) ?? 'Курс',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  (course['description'] as String?) ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                const SizedBox(height: 16),
                if (course['id'] != null)
                  _StartCourseButton(
                    courseId: course['id'] as String,
                    firstLessonModuleId: firstLessonModuleId,
                    firstLessonSlug: firstLesson?['slug']?.toString(),
                    firstLessonTitle: firstLesson?['title']?.toString(),
                  ),
              ],
            ),
          ),

          // Modules list
          if (modules.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Модулі курсу',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...modules.map((module) => _ModuleCard(module: module)),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Модулі поки що недоступні'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Помилка завантаження', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StartCourseButton extends ConsumerStatefulWidget {
  final String courseId;
  final String? firstLessonModuleId;
  final String? firstLessonSlug;
  final String? firstLessonTitle;

  const _StartCourseButton({
    required this.courseId,
    this.firstLessonModuleId,
    this.firstLessonSlug,
    this.firstLessonTitle,
  });

  @override
  ConsumerState<_StartCourseButton> createState() => _StartCourseButtonState();
}

class _StartCourseButtonState extends ConsumerState<_StartCourseButton> {
  bool _isLoading = false;

  Future<void> _startCourse() async {
    setState(() => _isLoading = true);

    try {
      await ApiClient().startCourse(widget.courseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Курс розпочато!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.firstLessonModuleId != null && widget.firstLessonSlug != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonScreen(
                moduleId: widget.firstLessonModuleId!,
                lessonSlug: widget.firstLessonSlug!,
                lessonTitle: widget.firstLessonTitle,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Помилка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _startCourse,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.play_arrow),
      label: Text(_isLoading ? 'Завантаження...' : 'Розпочати курс'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final Map<String, dynamic> module;

  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    final lessons = module['lessons'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.folder, color: Colors.blue.shade700),
        ),
        title: Text(
          module['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${lessons.length} уроків'),
        children: lessons
            .map((lesson) => _LessonTile(moduleId: module['id'] as String, lesson: lesson))
            .toList(),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final String moduleId;
  final Map<String, dynamic> lesson;

  const _LessonTile({required this.moduleId, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final count = (lesson['_count'] is Map)
        ? ((lesson['_count'] as Map)['challenges'] as int?)
        : null;

    return ListTile(
      leading: Icon(Icons.book, color: Colors.grey[600]),
      title: Text(lesson['title'] as String),
      subtitle: count != null ? Text('$count завдань') : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        final slug = lesson['slug'] as String?;
        if (slug == null) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonScreen(
              moduleId: moduleId,
              lessonSlug: slug,
              lessonTitle: lesson['title']?.toString(),
            ),
          ),
        );
      },
    );
  }
}
