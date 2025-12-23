import '../models/models.dart';
import '../core/network/api_client.dart';

class ChallengesService {
  final ApiClient _api;

  ChallengesService(this._api);

  Future<List<ChallengeCategory>> getCategories() async {
    try {
      final response = await _api.dio.get('/challenges/categories');
      final List<dynamic> data = response.data as List;
      return data.map((json) => ChallengeCategory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<Challenge>> getChallenges({
    String? category,
    String? difficulty,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _api.dio.get(
        '/challenges',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data as List;
      return data.map((json) => Challenge.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load challenges: $e');
    }
  }

  Future<Challenge> getChallengeById(String id) async {
    try {
      final response = await _api.dio.get('/challenges/$id');
      return Challenge.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load challenge: $e');
    }
  }

  Future<Submission> submitCode({
    required String challengeId,
    required String code,
    required String language,
  }) async {
    try {
      final response = await _api.dio.post(
        '/submissions',
        data: {
          'challengeId': challengeId,
          'code': code,
          'language': language,
        },
      );
      return Submission.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to submit code: $e');
    }
  }

  Future<List<Submission>> getUserSubmissions(String challengeId) async {
    try {
      final response = await _api.dio.get(
        '/submissions',
        queryParameters: {'challengeId': challengeId},
      );
      final List<dynamic> data = response.data as List;
      return data.map((json) => Submission.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load submissions: $e');
    }
  }
}
