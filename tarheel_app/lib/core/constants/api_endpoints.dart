class ApiEndpoints {
  // Base URL (For Android Emulator use 10.0.2.2, for iOS/Web/Device use machine IP or domain)
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1';
  static const String socketUrl = 'http://10.0.2.2:3000';

  // Auth
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String registerClient = '$baseUrl/auth/register/client';

  // Drivers
  static const String registerDriver = '$baseUrl/drivers/register';
  static const String driverMe = '$baseUrl/drivers/me';
  static String driverDetails(String id) => '$baseUrl/drivers/$id';

  // Trips
  static const String createTrip = '$baseUrl/trips';
  static const String tripsFeed = '$baseUrl/trips/feed';
  static const String myTripRequests = '$baseUrl/trips/my-requests';
  static String tripDetails(String id) => '$baseUrl/trips/$id';
  static String cancelTrip(String id) => '$baseUrl/trips/$id/cancel';

  // Offers
  static const String createOffer = '$baseUrl/offers';
  static const String myOffers = '$baseUrl/offers/my-offers';
  static String tripOffers(String tripId) => '$baseUrl/offers/trip/$tripId';

  // Contracts & Payments
  static const String acceptOffer = '$baseUrl/contracts/accept-offer';
  static const String myContracts = '$baseUrl/contracts/my-contracts';
  static String contractDetails(String id) => '$baseUrl/contracts/$id';
  static const String processEscrowPayment = '$baseUrl/payments/process-escrow';
  static String completeContract(String contractId) => '$baseUrl/payments/complete-contract/$contractId';

  // Chat
  static const String sendChatMessage = '$baseUrl/chat/send';
  static String contractChat(String contractId) => '$baseUrl/chat/contract/$contractId';
  static String tripChat(String tripId) => '$baseUrl/chat/trip/$tripId';

  // Support
  static const String createTicket = '$baseUrl/support/ticket';
  static const String myTickets = '$baseUrl/support/my-tickets';
  static String ticketDetails(String id) => '$baseUrl/support/tickets/$id';
  static String replyTicket(String id) => '$baseUrl/support/tickets/$id/reply';

  // Reviews
  static const String createReview = '$baseUrl/reviews';
  static const String submitReview = '$baseUrl/reviews';
  static String driverReviews(String driverId) => '$baseUrl/reviews/driver/$driverId';

  // Uploads
  static const String uploadSingle = '$baseUrl/uploads/single';
  static const String uploadVehiclePhotos = '$baseUrl/uploads/vehicle-photos';

  // Users
  static const String userProfile = '$baseUrl/users/profile';
  static const String walletTransactions = '$baseUrl/users/wallet/transactions';
  static const String userNotifications = '$baseUrl/users/notifications';
}
