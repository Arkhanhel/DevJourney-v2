import '../models/models.dart';
import '../core/network/api_client.dart';

class ProgressService {
  final ApiClient _api;

  ProgressService(this._api);

  Future<UserProgress> getUserProgress() async {
    try {
      final response = await _api.dio.get('/progress');
      return UserProgress.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load progress: $e');
    }
  }

  Future<List<Achievement>> getAchievements() async {
    try {
      final response = await _api.dio.get('/achievements');
      final List<dynamic> data = response.data as List;
      return data.map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load achievements: $e');
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _api.dio.get('/progress/statistics');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load statistics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final response = await _api.dio.get(
        '/progress/leaderboard',
        queryParameters: {'limit': limit},
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load leaderboard: $e');
    }
  }
}
