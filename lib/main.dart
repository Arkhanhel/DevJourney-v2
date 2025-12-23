import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/challenge_detail_screen.dart';
import 'screens/challenge_execution_screen.dart';
import 'screens/learning_categories_screen.dart';
import 'screens/my_submissions_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/achievements_screen.dart';
import 'providers/auth_provider.dart';
import 'models/models.dart';

void main() {
  runApp(
    const ProviderScope(
      child: DevJourneyApp(),
    ),
  );
}

class DevJourneyApp extends ConsumerWidget {
  const DevJourneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'DevJourney',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
        ),
      ),
      themeMode: ThemeMode.system,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/achievements': (context) => const AchievementsScreen(),
        '/learning-categories': (context) => const LearningCategoriesScreen(),
        '/my-submissions': (context) => const MySubmissionsScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/challenge-detail') {
          final challenge = settings.arguments as Challenge;
          return MaterialPageRoute(
            builder: (context) =>
                ChallengeDetailScreen(challengeId: challenge.id),
          );
        } else if (settings.name == '/challenge-execution') {
          final challenge = settings.arguments as Challenge;
          return MaterialPageRoute(
            builder: (context) =>
                ChallengeExecutionScreen(challenge: challenge),
          );
        }
        return null;
      },
      home: authState.isAuthenticated
          ? const HomeScreen()
          : authState.isLoading
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : const LoginScreen(),
    );
  }
}
