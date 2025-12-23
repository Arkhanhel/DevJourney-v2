import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/models.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider = StreamProvider<User?>((ref) async* {
  final api = ref.read(apiClientProvider);
  const storage = FlutterSecureStorage();

  // Check for existing access token
  final token = await storage.read(key: ApiConfig.accessTokenKey);

  if (token != null && !JwtDecoder.isExpired(token)) {
    try {
      final response = await api.getCurrentUser();
      yield User.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      await storage.delete(key: ApiConfig.accessTokenKey);
      await storage.delete(key: ApiConfig.refreshTokenKey);
      yield null;
    }
  } else {
    await storage.delete(key: ApiConfig.accessTokenKey);
    await storage.delete(key: ApiConfig.refreshTokenKey);
    yield null;
  }
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiClient _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._api) : super(const AsyncValue.loading());

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.login(email, password);
      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String?;

      await _storage.write(key: ApiConfig.accessTokenKey, value: accessToken);
      if (refreshToken != null) {
        await _storage.write(key: ApiConfig.refreshTokenKey, value: refreshToken);
      }

      final userResp = await _api.getCurrentUser();
      state = AsyncValue.data(User.fromJson(userResp.data as Map<String, dynamic>));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> register(String email, String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.register({
        'email': email,
        'username': username,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String?;

      await _storage.write(key: ApiConfig.accessTokenKey, value: accessToken);
      if (refreshToken != null) {
        await _storage.write(key: ApiConfig.refreshTokenKey, value: refreshToken);
      }

      final userResp = await _api.getCurrentUser();
      state = AsyncValue.data(User.fromJson(userResp.data as Map<String, dynamic>));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: ApiConfig.accessTokenKey);
    await _storage.delete(key: ApiConfig.refreshTokenKey);
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(api);
});
