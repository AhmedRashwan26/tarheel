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
  static String get googleLogin => '$baseUrl/auth/google';
  static String get bindPhoneSendOtp => '$baseUrl/auth/bind-phone/send-otp';
  static String get bindPhoneVerify => '$baseUrl/auth/bind-phone/verify';

  // Drivers
  static String get registerDriver => '$baseUrl/drivers/register';
  static String get driverMe => '$baseUrl/drivers/me';
  static String driverDetails(String id) => '$baseUrl/drivers/$id';

  // Trips
  static String get createTrip => '$baseUrl/trips';
  static String get tripsFeed => '$baseUrl/trips/feed';
  static String tripsFeedWithFilter({String? search, int? capacity}) {
    String q = '';
    if (search != null && search.trim().isNotEmpty) q += 'search=${Uri.encodeComponent(search.trim())}&';
    if (capacity != null) q += 'capacity=$capacity&';
    return q.isNotEmpty ? '$baseUrl/trips/feed?$q' : '$baseUrl/trips/feed';
  }
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
  static String get chatUnreadCount => '$baseUrl/chat/unread-count';
  static String chatMarkRead({String? contractId, String? tripRequestId}) {
    String q = '';
    if (contractId != null) q += 'contractId=$contractId&';
    if (tripRequestId != null) q += 'tripRequestId=$tripRequestId&';
    return '$baseUrl/chat/mark-read?$q';
  }

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

  // Admin Dashboard
  static String get adminFinancialOverview => '$baseUrl/admin/financial-overview';
  static String get adminPendingDrivers => '$baseUrl/admin/drivers/pending';
  static String get adminAllDrivers => '$baseUrl/admin/drivers';
  static String adminDriverDetails(String id) => '$baseUrl/admin/drivers/$id';
  static String adminApproveDriver(String id) => '$baseUrl/admin/drivers/$id/approve';
  static String adminRejectDriver(String id) => '$baseUrl/admin/drivers/$id/reject';
  static String adminSuspendDriver(String id) => '$baseUrl/admin/drivers/$id/suspend';
  static String adminUnsuspendDriver(String id) => '$baseUrl/admin/drivers/$id/unsuspend';
  static String get adminDisputes => '$baseUrl/admin/disputes';
  static String adminResolveDispute(String contractId) => '$baseUrl/admin/disputes/$contractId/resolve';
  static String get adminChats => '$baseUrl/admin/chats';
  static String adminChatMessages(String contractId) => '$baseUrl/admin/chats/$contractId';
  static String get adminBroadcastNotification => '$baseUrl/admin/notifications/broadcast';
  static String get adminSupportTickets => '$baseUrl/support/admin/tickets';
  static String adminUpdateTicketStatus(String id) => '$baseUrl/support/admin/tickets/$id/status';
  static String adminUsersPerformance({String? role, String? search}) {
    String q = '';
    if (role != null) q += 'role=$role&';
    if (search != null && search.isNotEmpty) q += 'search=${Uri.encodeComponent(search)}&';
    return '$baseUrl/admin/users/financial-performance?$q';
  }
  static String adminUserActivityHistory(String userId) => '$baseUrl/admin/users/$userId/activity-history';
}
