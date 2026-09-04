import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_endpoints.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  IO.Socket? socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _bidController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get bidStream => _bidController.stream;
  Stream<Map<String, dynamic>> get tripStream => _tripController.stream;

  SocketService._internal();

  void initSocket(String userId) {
    if (socket != null && socket!.connected) return;

    socket = IO.io(
      ApiEndpoints.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    socket?.onConnect((_) {
      debugPrint('🟢 Connected to Tarheel WebSocket');
      socket?.emit('authenticate', {'userId': userId});
    });

    socket?.on('new_chat_message', (data) {
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      }
    });

    socket?.on('new_bid_received', (data) {
      if (data is Map<String, dynamic>) {
        _bidController.add(data);
      }
    });

    socket?.on('bid_accepted', (data) {
      if (data is Map<String, dynamic>) {
        _bidController.add(data);
      }
    });

    socket?.on('new_trip_request', (data) {
      if (data is Map<String, dynamic>) {
        _tripController.add(data);
      }
    });

    socket?.onDisconnect((_) {
      debugPrint('🔴 Disconnected from Tarheel WebSocket');
    });
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
