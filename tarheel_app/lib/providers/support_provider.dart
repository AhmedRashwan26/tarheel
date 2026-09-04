import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';

class SupportProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<dynamic> _myTickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get myTickets => _myTickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyTickets({String? department}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(
        ApiEndpoints.myTickets,
        queryParameters: department != null ? {'department': department} : null,
      );
      _myTickets = response.data['data'] ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSupportTicket({
    required String department,
    required String subject,
    required String description,
    required String category,
    String? contractId,
    String? priority,
    String? appVersion,
    String? deviceInfo,
    String? attachments,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiEndpoints.createTicket,
        data: {
          'department': department,
          'subject': subject,
          'description': description,
          'category': category,
          if (contractId != null) 'contractId': contractId,
          if (priority != null) 'priority': priority,
          if (appVersion != null) 'appVersion': appVersion,
          if (deviceInfo != null) 'deviceInfo': deviceInfo,
          if (attachments != null) 'attachments': attachments,
        },
      );

      _isLoading = false;
      await fetchMyTickets();
      notifyListeners();
      return response.data['success'] == true;
    } catch (e) {
      _isLoading = false;
      if (e is DioException) {
        _errorMessage = e.error?.toString() ?? 'فشل فتح تذكرة الدعم';
      } else {
        _errorMessage = 'فشل فتح تذكرة الدعم';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> replyToTicket(String ticketId, String message, {String? attachmentUrl}) async {
    try {
      final response = await _api.post(
        ApiEndpoints.replyTicket(ticketId),
        data: {
          'message': message,
          if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        },
      );
      await fetchMyTickets();
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Error replying to ticket: $e');
      return false;
    }
  }
}
