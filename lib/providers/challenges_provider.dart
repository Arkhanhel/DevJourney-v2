import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/models.dart';
import '../core/network/api_client.dart';
import '../models/models.dart' as app_models;
import '../services/challenges_service.dart';
import '../services/progress_service.dart';

// Single challenge provider
final challengeProvider = FutureProvider.family<Challenge, String>((ref, id) async {
  final response = await ApiClient().getChallenge(id);
  return Challenge.fromJson(response.data);
});

// List of challenges (catalog)
final challengesListProvider = FutureProvider<List<app_models.Challenge>>((ref) async {
  final service = ChallengesService(ApiClient());
  return service.getChallenges();
});

// User progress for challenge
final challengeProgressProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, challengeId) async {
  final response = await ApiClient().getChallengeProgress(challengeId);
  return response.data as Map<String, dynamic>;
});

// User submissions
final mySubmissionsProvider = FutureProvider<List<Submission>>((ref) async {
  final response = await ApiClient().getMySubmissions();
  final List<dynamic> data = response.data;
  return data.map((json) => Submission.fromJson(json)).toList();
});

// User overall progress
final userProgressProvider = FutureProvider<app_models.UserProgress>((ref) async {
  final progressService = ProgressService(ApiClient());
  return progressService.getUserProgress();
});

// Leaderboard
final leaderboardProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, limit) async {
  final response = await ApiClient().getLeaderboard(limit: limit);
  return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
});
