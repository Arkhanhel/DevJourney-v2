import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';

/// Dio interceptor for handling JWT tokens
class AuthInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage storage;
  final Logger logger;

  AuthInterceptor({
    required this.dio,
    required this.storage,
    required this.logger,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add access token to all requests
    final path = options.path;
    final isAuthPath = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh');

    // Skip attaching token for auth endpoints to avoid using expired tokens on refresh
    if (!isAuthPath) {
      final accessToken = await storage.read(key: ApiConfig.accessTokenKey);
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    logger.d('→ ${options.method} ${options.path}');
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.d('← ${response.statusCode} ${response.requestOptions.path}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    logger.e('✗ ${err.response?.statusCode} ${err.requestOptions.path}');

    // If 401 (unauthorized), try to refresh token
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await storage.read(key: ApiConfig.refreshTokenKey);
        
        if (refreshToken != null) {
          // Attempt token refresh
          final response = await dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(
              headers: {'Authorization': null}, // Don't use expired token
            ),
          );

          if (response.statusCode == 200) {
            final newAccessToken = response.data['accessToken'];
            final newRefreshToken = response.data['refreshToken'];

            // Save new tokens
            await storage.write(key: ApiConfig.accessTokenKey, value: newAccessToken);
            if (newRefreshToken != null) {
              await storage.write(key: ApiConfig.refreshTokenKey, value: newRefreshToken);
            }

            // Retry original request with new token
            final opts = Options(
              method: err.requestOptions.method,
              headers: {
                ...err.requestOptions.headers,
                'Authorization': 'Bearer $newAccessToken',
              },
            );

            final cloneReq = await dio.request(
              err.requestOptions.path,
              options: opts,
              data: err.requestOptions.data,
              queryParameters: err.requestOptions.queryParameters,
            );

            return handler.resolve(cloneReq);
          }
        }

        // If refresh failed, clear tokens and redirect to login
        await _clearTokens();
      } catch (e) {
        logger.e('Token refresh failed: $e');
        await _clearTokens();
      }
    }

    return handler.next(err);
  }

  Future<void> _clearTokens() async {
    await storage.delete(key: ApiConfig.accessTokenKey);
    await storage.delete(key: ApiConfig.refreshTokenKey);
    await storage.delete(key: ApiConfig.userIdKey);
  }
}
