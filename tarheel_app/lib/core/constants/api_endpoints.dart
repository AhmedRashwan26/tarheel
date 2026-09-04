import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static const String _customBaseUrl = String.fromEnvironment('API_BASE_URL');

  // Determine Base URL dynamically based on running platform
  static String get baseDomain {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }
    if (kIsWeb) {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        return 'http://localhost:3000';
      }
      return Uri.base.origin;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static String get baseUrl => '$baseDomain/api/v1';
  static String get socketUrl => baseDomain;

  // Auth
  static String get sendOtp => '$baseUrl/auth/send-otp';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get registerClient => '$baseUrl/auth/register/client';

  // Drivers
  static String get registerDriver => '$baseUrl/drivers/register';
  static String get driverMe => '$baseUrl/drivers/me';
  static String driverDetails(String id) => '$baseUrl/drivers/$id';

  // Trips
  static String get createTrip => '$baseUrl/trips';
  static String get tripsFeed => '$baseUrl/trips/feed';
  static String get myTripRequests => '$baseUrl/trips/my-requests';
  static String tripDetails(String id) => '$baseUrl/trips/$id';
  static String cancelTrip(String id) => '$baseUrl/trips/$id/cancel';

  // Offers
  static String get createOffer => '$baseUrl/offers';
  static String get myOffers => '$baseUrl/offers/my-offers';
  static String tripOffers(String tripId) => '$baseUrl/offers/trip/$tripId';

  // Contracts & Payments
  static String get acceptOffer => '$baseUrl/contracts/accept-offer';
  static String get myContracts => '$baseUrl/contracts/my-contracts';
  static String contractDetails(String id) => '$baseUrl/contracts/$id';
  static String driverSchedule(String date) => '$baseUrl/contracts/driver-schedule?date=$date';
  static String get updateScheduleStatus => '$baseUrl/contracts/driver-schedule/update-status';
  static String get processEscrowPayment => '$baseUrl/payments/process-escrow';
  static String completeContract(String contractId) => '$baseUrl/payments/complete-contract/$contractId';

  // Chat
  static String get sendChatMessage => '$baseUrl/chat/send';
  static String contractChat(String contractId) => '$baseUrl/chat/contract/$contractId';
  static String tripChat(String tripId) => '$baseUrl/chat/trip/$tripId';

  // Support
  static String get createTicket => '$baseUrl/support/ticket';
  static String get myTickets => '$baseUrl/support/my-tickets';
  static String ticketDetails(String id) => '$baseUrl/support/tickets/$id';
  static String replyTicket(String id) => '$baseUrl/support/tickets/$id/reply';

  // Reviews
  static String get createReview => '$baseUrl/reviews';
  static String get submitReview => '$baseUrl/reviews';
  static String driverReviews(String driverId) => '$baseUrl/reviews/driver/$driverId';

  // Uploads
  static String get uploadSingle => '$baseUrl/uploads/single';
  static String get uploadVehiclePhotos => '$baseUrl/uploads/vehicle-photos';

  // Users
  static String get userProfile => '$baseUrl/users/profile';
  static String get walletTransactions => '$baseUrl/users/wallet/transactions';
  static String get userNotifications => '$baseUrl/users/notifications';
}
