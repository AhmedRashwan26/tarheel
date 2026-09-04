import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/socket/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<dynamic> _messages = [];
  bool _isLoading = false;
  String? _currentContractId;

  List<dynamic> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider() {
    SocketService().messageStream.listen((data) {
      if (data['message'] != null) {
        final newMsg = data['message'];
        if (_currentContractId != null && newMsg['contractId'] == _currentContractId) {
          _messages.add(newMsg);
          notifyListeners();
        }
      }
    });
  }

  Future<void> loadContractMessages(String contractId) async {
    _currentContractId = contractId;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiEndpoints.contractChat(contractId));
      _messages = response.data['data'] ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendTextMessage({
    required String receiverId,
    required String content,
    String? contractId,
    String? tripRequestId,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.sendChatMessage,
        data: {
          'receiverId': receiverId,
          'messageType': 'TEXT',
          'content': content,
          if (contractId != null) 'contractId': contractId,
          if (tripRequestId != null) 'tripRequestId': tripRequestId,
        },
      );

      if (response.data['success'] == true) {
        _messages.add(response.data['data']['data']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending text message: $e');
      return false;
    }
  }

  Future<bool> sendVoiceNote({
    required String receiverId,
    required String mediaUrl,
    required int durationSeconds,
    String? contractId,
    String? tripRequestId,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.sendChatMessage,
        data: {
          'receiverId': receiverId,
          'messageType': 'VOICE_NOTE',
          'mediaUrl': mediaUrl,
          'durationSeconds': durationSeconds,
          if (contractId != null) 'contractId': contractId,
          if (tripRequestId != null) 'tripRequestId': tripRequestId,
        },
      );

      if (response.data['success'] == true) {
        _messages.add(response.data['data']['data']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending voice note: $e');
      return false;
    }
  }

  Future<bool> sendLocationMessage({
    required String receiverId,
    required double latitude,
    required double longitude,
    String? locationAddress,
    String? content,
    String? contractId,
    String? tripRequestId,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.sendChatMessage,
        data: {
          'receiverId': receiverId,
          'messageType': 'LOCATION',
          'latitude': latitude,
          'longitude': longitude,
          'locationAddress': locationAddress ?? 'موقع مباشر',
          'content': content ?? '📍 موقعي الحالي',
          if (contractId != null) 'contractId': contractId,
          if (tripRequestId != null) 'tripRequestId': tripRequestId,
        },
      );

      if (response.data['success'] == true) {
        _messages.add(response.data['data']['data']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending location message: $e');
      return false;
    }
  }
}
