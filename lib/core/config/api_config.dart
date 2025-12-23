class ApiConfig {
  // Backend API base URL
  // For development, use your machine's IP for physical devices
  // or localhost for emulator/web
  static const String baseUrl = 'http://192.168.0.102:3001/api';
  
  // WebSocket URL
  static const String wsUrl = 'http://192.168.0.102:3001';
  
  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  
  // WebSocket namespaces
  static const String submissionsNamespace = '/submissions';
}
