import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';

class TripProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> _myTrips = [];
  List<dynamic> _openTripsFeed = [];
  List<dynamic> _myContracts = [];
  Map<String, dynamic>? _selectedTripDetails;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get myTrips => _myTrips;
  List<dynamic> get openTripsFeed => _openTripsFeed;
  List<dynamic> get myContracts => _myContracts;
  Map<String, dynamic>? get selectedTripDetails => _selectedTripDetails;

  Future<bool> createTripRequest(Map<String, dynamic> tripData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post(ApiEndpoints.createTrip, data: tripData);
      _isLoading = false;
      await fetchMyTripRequests();
      notifyListeners();
      return response.data['success'] == true;
    } catch (e) {
      _isLoading = false;
      if (e is DioException) {
        _errorMessage = e.error?.toString() ?? 'فشل نشر طلب المشوار';
      } else {
        _errorMessage = 'فشل نشر طلب المشوار';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyTripRequests() async {
    try {
      final response = await _api.get(ApiEndpoints.myTripRequests);
      _myTrips = response.data['data'] ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching my trips: $e');
    }
  }

  Future<void> fetchOpenTripsFeed() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get(ApiEndpoints.tripsFeed);
      _openTripsFeed = response.data['data'] ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTripDetails(String tripId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get(ApiEndpoints.tripDetails(tripId));
      _selectedTripDetails = response.data['data'];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitDriverOffer({
    required String tripRequestId,
    required double offerPrice,
    String? driverNotes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiEndpoints.createOffer,
        data: {
          'tripRequestId': tripRequestId,
          'offerPrice': offerPrice,
          'driverNotes': driverNotes,
        },
      );
      _isLoading = false;
      await fetchOpenTripsFeed();
      notifyListeners();
      return response.data['success'] == true;
    } catch (e) {
      _isLoading = false;
      if (e is DioException) {
        _errorMessage = e.error?.toString() ?? 'فشل تقديم عرض السعر';
      } else {
        _errorMessage = 'فشل تقديم عرض السعر';
      }
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> acceptOffer(String offerId, {String? paymentType}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiEndpoints.acceptOffer,
        data: {
          'offerId': offerId,
          if (paymentType != null) 'paymentType': paymentType,
        },
      );
      _isLoading = false;
      notifyListeners();
      return response.data['data'];
    } catch (e) {
      _isLoading = false;
      if (e is DioException) {
        _errorMessage = e.error?.toString() ?? 'فشل قبول العرض';
      } else {
        _errorMessage = 'فشل قبول العرض';
      }
      notifyListeners();
      return null;
    }
  }

  Future<bool> processEscrowPayment({
    required String contractId,
    required String paymentMethod,
    required bool acknowledgeAntiCashPolicy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiEndpoints.processEscrowPayment,
        data: {
          'contractId': contractId,
          'paymentMethod': paymentMethod,
          'acknowledgeAntiCashPolicy': acknowledgeAntiCashPolicy,
        },
      );
      _isLoading = false;
      await fetchMyContracts();
      notifyListeners();
      return response.data['success'] == true;
    } catch (e) {
      _isLoading = false;
      if (e is DioException) {
        _errorMessage = e.error?.toString() ?? 'فشل إتمام الدفع';
      } else {
        _errorMessage = 'فشل إتمام الدفع';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyContracts() async {
    try {
      final response = await _api.get(ApiEndpoints.myContracts);
      _myContracts = response.data['data'] ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching contracts: $e');
    }
  }
}
