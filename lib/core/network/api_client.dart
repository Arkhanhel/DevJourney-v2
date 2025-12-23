import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import 'auth_interceptor.dart';

/// Singleton API client for all HTTP requests
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  late final FlutterSecureStorage _storage;
  late final Logger _logger;

  ApiClient._internal() {
    _storage = const FlutterSecureStorage();
    _logger = Logger();

    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(
      AuthInterceptor(
        dio: _dio,
        storage: _storage,
        logger: _logger,
      ),
    );

    // Logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => _logger.d(obj),
      ),
    );
  }

  Dio get dio => _dio;
  FlutterSecureStorage get storage => _storage;
  Logger get logger => _logger;

  // === AUTH ENDPOINTS ===
  Future<Response> register(Map<String, dynamic> data) {
    return _dio.post('/auth/register', data: data);
  }

  Future<Response> login(String email, String password) {
    return _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> getCurrentUser() {
    return _dio.get('/auth/me');
  }

  // === TRACKS ENDPOINTS ===
  Future<Response> getTracks() {
    return _dio.get('/tracks');
  }

  Future<Response> getTrack(String slug) {
    return _dio.get('/tracks/$slug');
  }

  // === COURSES ENDPOINTS ===
  Future<Response> getCourses({String? trackId}) {
    return _dio.get('/courses', queryParameters: trackId != null ? {'trackId': trackId} : null);
  }

  Future<Response> getCourse(String slug) {
    return _dio.get('/courses/$slug');
  }

  Future<Response> startCourse(String courseId) {
    return _dio.post('/courses/$courseId/start');
  }

  // === LESSONS ENDPOINTS ===
  Future<Response> getLesson(String moduleId, String slug, {String? locale}) {
    return _dio.get(
      '/lessons/$moduleId/$slug',
      queryParameters: locale != null ? {'locale': locale} : null,
    );
  }

  Future<Response> getNextLesson(String lessonId) {
    return _dio.get('/lessons/$lessonId/next');
  }

  Future<Response> updateLessonProgress(String lessonId, String status) {
    return _dio.post('/lessons/$lessonId/progress', data: {
      'status': status,
    });
  }

  // === CHALLENGES ENDPOINTS ===
  Future<Response> getChallenges() {
    return _dio.get('/challenges');
  }

  Future<Response> getChallenge(String id) {
    return _dio.get('/challenges/$id');
  }

  Future<Response> getNextChallenge(String id) {
    return _dio.get('/challenges/$id/next');
  }

  // === SUBMISSIONS ENDPOINTS ===
  Future<Response> createSubmission({
    required String challengeId,
    required String code,
    required String language,
  }) {
    return _dio.post('/submissions', data: {
      'challengeId': challengeId,
      'code': code,
      'language': language,
    });
  }

  Future<Response> getSubmission(String id) {
    return _dio.get('/submissions/$id');
  }

  Future<Response> getMySubmissions() {
    return _dio.get('/submissions/my');
  }

  Future<Response> getSubmissionStatus(String id) {
    return _dio.get('/submissions/$id/status');
  }

  // === PROGRESS ENDPOINTS ===
  Future<Response> getUserProgress() {
    return _dio.get('/progress');
  }

  Future<Response> getChallengeProgress(String challengeId) {
    return _dio.get('/progress/challenge/$challengeId');
  }

  Future<Response> getLeaderboard({int limit = 10}) {
    return _dio.get('/progress/leaderboard', queryParameters: {'limit': limit});
  }

  // === AI ENDPOINTS ===
  Future<Response> getHint({
    required String challengeId,
    required String userCode,
    String? failingOutput,
    required int attempts,
    String locale = 'uk',
  }) {
    return _dio.post('/ai/hint', data: {
      'challengeId': challengeId,
      'userCode': userCode,
      'failingOutput': failingOutput,
      'attempts': attempts,
      'locale': locale,
    });
  }

  // === PROFILE ===
  Future<Response> updateUserProfile({
    int? age,
    List<String>? interests,
    String? preferredLanguage,
    String? skillLevel,
    String? learningGoals,
  }) {
    return _dio.put('/profile', data: {
      if (age != null) 'age': age,
      if (interests != null) 'interests': interests,
      if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
      if (skillLevel != null) 'skillLevel': skillLevel,
      if (learningGoals != null) 'learningGoals': learningGoals,
    });
  }

  Future<Response> analyzeCode({
    required String code,
    required String language,
    String locale = 'uk',
  }) {
    return _dio.post('/ai/analyze', data: {
      'code': code,
      'language': language,
      'locale': locale,
    });
  }

  // === TOKEN MANAGEMENT ===
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: ApiConfig.accessTokenKey, value: accessToken);
    await _storage.write(key: ApiConfig.refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: ApiConfig.accessTokenKey);
    await _storage.delete(key: ApiConfig.refreshTokenKey);
    await _storage.delete(key: ApiConfig.userIdKey);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: ApiConfig.accessTokenKey);
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: ApiConfig.refreshTokenKey);
  }
}
