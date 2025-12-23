import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';
import '../config/api_config.dart';

/// WebSocket service for real-time submission updates
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  io.Socket? _socket;
  final Logger _logger = Logger();
  bool _isConnected = false;
  final Map<String, void Function(Map<String, dynamic>)> _submissionHandlers = {};
  bool _listenersAttached = false;

  WebSocketService._internal();

  /// Connect to WebSocket server
  Future<void> connect(String accessToken) async {
    if (_isConnected) {
      _logger.i('WebSocket already connected');
      return;
    }

    try {
      final base = ApiConfig.wsUrl.endsWith('/')
          ? ApiConfig.wsUrl.substring(0, ApiConfig.wsUrl.length - 1)
          : ApiConfig.wsUrl;
      final namespaceUrl = '$base${ApiConfig.submissionsNamespace}';

      _socket = io.io(
        namespaceUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $accessToken'})
            .setPath('/socket.io')
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        _logger.i('✅ WebSocket connected');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        _logger.w('❌ WebSocket disconnected');
      });

      _socket!.onError((error) {
        _logger.e('WebSocket error: $error');
      });

      _socket!.connect();
    } catch (e) {
      _logger.e('Failed to connect WebSocket: $e');
    }
  }

  /// Subscribe to submission updates
  void subscribeToSubmission(
    String submissionId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    if (!_isConnected || _socket == null) {
      _logger.w('WebSocket not connected');
      return;
    }

    _submissionHandlers[submissionId] = onUpdate;

    if (!_listenersAttached) {
      _listenersAttached = true;

      _socket!.on('update', (data) {
        try {
          final payload = (data as Map).cast<String, dynamic>();
          final id = payload['submissionId']?.toString();
          if (id == null) return;
          final handler = _submissionHandlers[id];
          if (handler != null) handler(payload);
        } catch (e) {
          _logger.e('Failed to handle update event: $e');
        }
      });

      _socket!.on('test-result', (data) {
        try {
          final payload = (data as Map).cast<String, dynamic>();
          final id = payload['submissionId']?.toString();
          if (id == null) return;
          final handler = _submissionHandlers[id];
          if (handler != null) {
            handler({
              'type': 'test-result',
              ...payload,
            });
          }
        } catch (e) {
          _logger.e('Failed to handle test-result event: $e');
        }
      });
    }

    // Emit subscribe event
    _socket!.emit('subscribe', {'submissionId': submissionId});
  }

  /// Unsubscribe from submission updates
  void unsubscribeFromSubmission(String submissionId) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('unsubscribe', {'submissionId': submissionId});
    _submissionHandlers.remove(submissionId);

    if (_submissionHandlers.isEmpty && _listenersAttached) {
      _socket!.off('update');
      _socket!.off('test-result');
      _listenersAttached = false;
    }
  }

  /// Disconnect from WebSocket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _logger.i('WebSocket disconnected and disposed');
    }
  }

  bool get isConnected => _isConnected;
}
