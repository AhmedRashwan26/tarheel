import 'package:flutter/material.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/socket/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<dynamic> _messages = [];
  bool _isLoading = false;
  String? _currentContractId;
  String? _currentTripRequestId;
  int _unreadCount = 0;
  Map<String, int> _unreadByContract = {};

  List<dynamic> get messages => _messages;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  Map<String, int> get unreadByContract => _unreadByContract;
  String? get currentContractId => _currentContractId;
  String? get currentTripRequestId => _currentTripRequestId;

  ChatProvider() {
    // Listen for real-time incoming chat messages
    SocketService().messageStream.listen((data) {
      if (data['message'] != null) {
        final newMsg = data['message'];
        final contractId = newMsg['contractId'];
        final tripRequestId = newMsg['tripRequestId'];

        final isCurrentChat = (_currentContractId != null && contractId == _currentContractId) ||
            (_currentTripRequestId != null && tripRequestId == _currentTripRequestId);

        if (isCurrentChat) {
          _messages.add(newMsg);
          // Mark immediately as read since user is inside this room
          markAsRead(contractId: _currentContractId, tripRequestId: _currentTripRequestId);
          notifyListeners();
        } else {
          _unreadCount++;
          if (contractId != null) {
            _unreadByContract[contractId] = (_unreadByContract[contractId] ?? 0) + 1;
          }
          notifyListeners();
        }
      }
    });

    // Listen for real-time read receipt updates
    SocketService().readReceiptStream.listen((data) {
      final contractId = data['contractId'];
      final tripRequestId = data['tripRequestId'];

      final isCurrentChat = (_currentContractId != null && contractId == _currentContractId) ||
          (_currentTripRequestId != null && tripRequestId == _currentTripRequestId);

      if (isCurrentChat) {
        for (var msg in _messages) {
          if (msg is Map) {
            msg['isRead'] = true;
          }
        }
        notifyListeners();
      }
    });
  }

  void setCurrentRoom({String? contractId, String? tripRequestId}) {
    _currentContractId = contractId;
    _currentTripRequestId = tripRequestId;
  }

  void clearCurrentRoom() {
    _currentContractId = null;
    _currentTripRequestId = null;
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _api.get(ApiEndpoints.chatUnreadCount);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        _unreadCount = data['totalUnread'] ?? 0;
        final list = data['unreadByContract'] as List? ?? [];
        _unreadByContract = {
          for (var item in list)
            if (item['contractId'] != null)
              item['contractId'].toString(): (item['_count']?['id'] ?? 0) as int
        };
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching chat unread count: $e');
    }
  }

  Future<void> markAsRead({String? contractId, String? tripRequestId}) async {
    try {
      await _api.patch(ApiEndpoints.chatMarkRead(
        contractId: contractId,
        tripRequestId: tripRequestId,
      ));
      await fetchUnreadCount();
    } catch (e) {
      debugPrint('Error marking chat messages as read: $e');
    }
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
      // Refresh unread counts since backend marks them read upon fetching
      fetchUnreadCount();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTripMessages(String tripRequestId) async {
    _currentTripRequestId = tripRequestId;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiEndpoints.tripChat(tripRequestId));
      _messages = response.data['data'] ?? [];
      _isLoading = false;
      notifyListeners();
      fetchUnreadCount();
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
