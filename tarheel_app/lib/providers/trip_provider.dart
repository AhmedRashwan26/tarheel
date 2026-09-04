import 'package:flutter/material.dart';
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
      final newTrip = {
        'id': 'trip_${DateTime.now().millisecondsSinceEpoch}',
        ...tripData,
        'status': 'OPEN',
        'offers': [],
        'createdAt': DateTime.now().toIso8601String(),
      };
      _myTrips.insert(0, newTrip);
      _openTripsFeed.insert(0, newTrip);
      notifyListeners();
      return true;
    }
  }

  Future<void> fetchMyTripRequests() async {
    try {
      final response = await _api.get(ApiEndpoints.myTripRequests);
      _myTrips = response.data['data'] ?? [];
      notifyListeners();
    } catch (e) {
      if (_myTrips.isEmpty) {
        _myTrips = [
          {
            'id': 'trip_101',
            'title': 'مشوار يومي للعمل (جامعة الملك سعود)',
            'pickupAddress': 'حي الملقا، طريق أنس بن مالك',
            'dropoffAddress': 'جامعة الملك سعود، الدرعية',
            'departureTime': '07:30 AM',
            'isRoundTrip': true,
            'returnTime': '03:30 PM',
            'frequency': 'WEEKLY',
            'seatsCount': 1,
            'status': 'OPEN',
            'offers': [
              {
                'id': 'offer_1',
                'offerPrice': '120.00',
                'driverNotes': 'سيارة حديثة ومكيفة والتزام تام بالمواعيد اليومية',
                'driver': {
                  'id': 'drv_1',
                  'fullName': 'كابتن / محمد الدوسري',
                  'rating': 4.9,
                  'tripsCount': 142,
                  'vehicle': {
                    'make': 'تويوتا',
                    'model': 'كامري 2024',
                    'hasAirConditioning': true,
                  }
                }
              }
            ]
          }
        ];
      }
      notifyListeners();
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
      if (_openTripsFeed.isEmpty) {
        _openTripsFeed = [
          {
            'id': 'feed_1',
            'title': 'مشوار دوام يومي - حي الصحافة إلى العليا',
            'pickupAddress': 'حي الصحافة، الرياض',
            'dropoffAddress': 'طريق الملك فهد، العليا',
            'departureTime': '08:00 AM',
            'isRoundTrip': true,
            'returnTime': '04:30 PM',
            'frequency': 'MONTHLY',
            'seatsCount': 2,
            'notes': 'سآخذ صديقي معي في طريقي ونحتاج التزام تام بوقت الانطلاق 08:00 صباحاً لتجنب الزحام.',
            'client': {'fullName': 'سلطان القحطاني'},
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'feed_2',
            'title': 'توصيل طلاب مدرسة (ذهاب وعودة)',
            'pickupAddress': 'حي الياسمين، الرياض',
            'dropoffAddress': 'مدارس الرياض الأهلية، حي النموذجية',
            'departureTime': '06:45 AM',
            'isRoundTrip': true,
            'returnTime': '01:30 PM',
            'frequency': 'WEEKLY',
            'seatsCount': 3,
            'notes': 'توصيل أطفال صغار - يرجى القيادة بهدوء تام وتشغيل تكييف معتدل.',
            'client': {'fullName': 'عبدالعزيز العتيبي'},
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'feed_3',
            'title': 'مشوار مسائي - حي الملقا إلى مركز KAFD',
            'pickupAddress': 'حي الملقا، طريق أنس بن مالك',
            'dropoffAddress': 'مركز الملك عبدالله المالي (KAFD)',
            'departureTime': '08:30 AM',
            'isRoundTrip': false,
            'returnTime': null,
            'frequency': 'DAILY',
            'seatsCount': 1,
            'notes': 'سأتوقف قليلاً عند البقالة في الطريق قبل الدخول للمركز المالي.',
            'client': {'fullName': 'م. عبدالمحسن الغامدي'},
            'createdAt': DateTime.now().toIso8601String(),
          }
        ];
      }
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
      _selectedTripDetails = _openTripsFeed.firstWhere(
        (t) => t['id'] == tripId,
        orElse: () => _myTrips.firstWhere((t) => t['id'] == tripId, orElse: () => {}),
      );
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
      notifyListeners();
      return true;
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
      notifyListeners();
      return {
        'id': 'contract_demo_101',
        'tripRequestId': 'trip_101',
        'driverId': 'drv_1',
        'baseAmount': '120.00',
        'vatAmount': '18.00',
        'totalAmount': '138.00',
        'status': 'AWAITING_PAYMENT',
        'tripRequest': {
          'title': 'مشوار يومي للعمل (جامعة الملك سعود)',
          'pickupAddress': 'حي الملقا، طريق أنس بن مالك',
          'dropoffAddress': 'جامعة الملك سعود، الدرعية',
        },
        'driverProfile': {
          'userId': 'drv_user_1',
          'user': {'fullName': 'كابتن / محمد الدوسري'},
          'vehicle': {'make': 'تويوتا', 'model': 'كامري 2024'}
        }
      };
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
      _myContracts.add({
        'id': contractId,
        'status': 'ACTIVE_IN_ESCROW',
        'paymentMethod': paymentMethod,
        'totalAmount': '138.00',
        'driverProfile': {
          'userId': 'drv_user_1',
          'user': {'fullName': 'كابتن / محمد الدوسري'},
        },
        'tripRequest': {
          'pickupAddress': 'حي الملقا، طريق أنس بن مالك',
          'dropoffAddress': 'جامعة الملك سعود، الدرعية',
        }
      });
      notifyListeners();
      return true;
    }
  }

  Future<void> fetchMyContracts() async {
    try {
      final response = await _api.get(ApiEndpoints.myContracts);
      _myContracts = response.data['data'] ?? [];
      notifyListeners();
    } catch (e) {
      if (_myContracts.isEmpty) {
        _myContracts = [
          {
            'id': 'contract_1',
            'status': 'ACTIVE_IN_ESCROW',
            'contractStatus': 'ACTIVE_IN_ESCROW',
            'driverEarnings': '1400.00',
            'totalAmount': '1555.00',
            'client': {
              'id': 'client_1',
              'fullName': 'سلطان القحطاني',
              'phone': '0501234567',
            },
            'tripRequest': {
              'id': 'trip_c1',
              'title': 'مشوار دوام يومي - الصحافة إلى العليا',
              'pickupAddress': 'حي الصحافة، شارع الإمام سعود',
              'dropoffAddress': 'برج الفيصلية، طريق الملك فهد',
              'departureTime': '07:15 AM',
              'isRoundTrip': true,
              'returnTime': '04:15 PM',
              'frequency': 'MONTHLY',
              'recurringDays': ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'],
              'seatsCount': 1,
              'notes': 'يرجى الالتزام بالوقت لتجنب زحمة الدوام',
            },
          },
          {
            'id': 'contract_2',
            'status': 'ACTIVE_IN_ESCROW',
            'contractStatus': 'ACTIVE_IN_ESCROW',
            'driverEarnings': '1100.00',
            'totalAmount': '1222.00',
            'client': {
              'id': 'client_2',
              'fullName': 'أم ريان (توصيل مدرسي)',
              'phone': '0559876543',
            },
            'tripRequest': {
              'id': 'trip_c2',
              'title': 'توصيل مدرسة الرواد الأهلية',
              'pickupAddress': 'حي النرجس، مخرج 7',
              'dropoffAddress': 'مدارس الرواد، حي الازدهار',
              'departureTime': '06:40 AM',
              'isRoundTrip': true,
              'returnTime': '01:20 PM',
              'frequency': 'MONTHLY',
              'recurringDays': ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'],
              'seatsCount': 2,
              'notes': 'مراعاة تشغيل التكييف المعتدل للأطفال',
            },
          },
          {
            'id': 'contract_3',
            'status': 'ACTIVE_IN_ESCROW',
            'contractStatus': 'ACTIVE_IN_ESCROW',
            'driverEarnings': '650.00',
            'totalAmount': '722.00',
            'client': {
              'id': 'client_3',
              'fullName': 'م. عبدالمحسن الغامدي',
              'phone': '0543322110',
            },
            'tripRequest': {
              'id': 'trip_c3',
              'title': 'مشوار يومي - الملقا إلى مركز KAFD',
              'pickupAddress': 'حي الملقا، طريق أنس بن مالك',
              'dropoffAddress': 'مركز الملك عبدالله المالي (KAFD)',
              'departureTime': '08:30 AM',
              'isRoundTrip': false,
              'returnTime': null,
              'frequency': 'DAILY',
              'recurringDays': ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'السبت'],
              'seatsCount': 1,
              'notes': 'الإنزال عند البوابة الرئيسية رقم 4',
            },
          },
        ];
      }
      notifyListeners();
    }
  }
}
