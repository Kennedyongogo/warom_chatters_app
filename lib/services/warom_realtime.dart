import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config.dart';
import 'warom_auth.dart';

typedef JsonMap = Map<String, dynamic>;

/// Socket.IO bridge for presence, chat fan-out, and WebRTC call signalling.
class WaromRealtime {
  WaromRealtime._();
  static final instance = WaromRealtime._();

  io.Socket? _socket;
  final _incomingCalls = StreamController<JsonMap>.broadcast();
  final _callSignals = StreamController<JsonMap>.broadcast();
  final _callStatus = StreamController<JsonMap>.broadcast();

  Stream<JsonMap> get incomingCalls => _incomingCalls.stream;
  Stream<JsonMap> get callSignals => _callSignals.stream;
  Stream<JsonMap> get callStatus => _callStatus.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    final token = WaromAuth.instance.token;
    if (token == null || token.isEmpty) return;
    if (_socket?.connected == true) return;

    await disconnect();

    final socket = io.io(
      kWaromApiBase,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1200)
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {});
    socket.on('call:incoming', (data) {
      final map = _asMap(data);
      if (map != null) _incomingCalls.add(map);
    });
    socket.on('call:signal', (data) {
      final map = _asMap(data);
      if (map != null) _callSignals.add(map);
    });
    socket.on('call:status', (data) {
      final map = _asMap(data);
      if (map != null) _callStatus.add(map);
    });

    _socket = socket;
    socket.connect();
  }

  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    socket?.dispose();
  }

  void sendCallSignal({
    required String toUserId,
    required String callId,
    required JsonMap signal,
  }) {
    _socket?.emit('call:signal', {
      'to_user_id': toUserId,
      'call_id': callId,
      'signal': signal,
    });
  }

  JsonMap? _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}
