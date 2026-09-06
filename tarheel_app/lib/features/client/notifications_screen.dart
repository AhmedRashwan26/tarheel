import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'trip_offers_screen.dart';
import '../driver/driver_schedule_and_contracts_screen.dart';
import '../chat/chat_room_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.get(ApiEndpoints.userNotifications);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        setState(() {
          _notifications = data.map((item) => Map<String, dynamic>.from(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _notifications = [];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل الإشعارات حالياً، يرجى المحاولة لاحقاً';
      });
    }
  }

  String _formatTimeAgo(String? isoString) {
    if (isoString == null) return '';
    try {
      final dateTime = DateTime.parse(isoString);
      final difference = DateTime.now().difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} يوم';
      } else {
        return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
      }
    } catch (_) {
      return '';
    }
  }

  Map<String, dynamic>? _parseMetadata(dynamic metadata) {
    if (metadata == null) return null;
    if (metadata is Map<String, dynamic>) return metadata;
    if (metadata is String && metadata.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(metadata);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    final fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '${ApiEndpoints.baseDomain}$imageUrl';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.black,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.8,
                      maxScale: 3.5,
                      child: Image.network(
                        fullUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 300,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(color: AppColors.accent),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          color: Colors.grey[900],
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded, color: Colors.white54, size: 50),
                              SizedBox(height: 8),
                              Text('تعذر تحميل الصورة', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: AppColors.cardDark,
                      width: double.infinity,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التنبيهات والإشعارات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: AppColors.accent,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 54),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchNotifications,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: const Icon(Icons.notifications_off_rounded, size: 60, color: Colors.white38),
              ),
              const SizedBox(height: 20),
              const Text(
                'لا توجد إشعارات حتى الآن',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'عندما يقدم الكباتن عروضاً على مشاويرك ستظهر جميع التفاصيل وصور السيارات هنا فوراً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        final metadata = _parseMetadata(notif['metadata']);
        return _buildNotificationCard(notif, metadata);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, Map<String, dynamic>? metadata) {
    final title = notif['title'] ?? 'إشعار جديد';
    final message = notif['message'] ?? '';
    final timeAgo = _formatTimeAgo(notif['createdAt']);
    final isRead = notif['isRead'] == true;
    final tripId = metadata?['tripId'];
    final offerPrice = metadata?['offerPrice'];
    final carPhotoInteriorUrl = (metadata?['carPhotoInteriorUrl'] ?? metadata?['carPhotoFrontUrl'])?.toString();
    final carFullName = metadata?['carFullName'] ?? '';
    final driverName = metadata?['driverName'] ?? '';
    final driverRating = metadata?['driverRating'];

    final hasInteriorPhoto = carPhotoInteriorUrl != null && carPhotoInteriorUrl.isNotEmpty;

    final isChatMessage = notif['type'] == 'CHAT_MESSAGE_RECEIVED';
    final isBidAccepted = notif['type'] == 'BID_ACCEPTED';
    final driverEarnings = metadata?['driverEarnings'];

    Color cardBorderColor;
    if (isRead) {
      cardBorderColor = Colors.white10;
    } else if (isChatMessage) {
      cardBorderColor = const Color(0xFF25D366).withOpacity(0.7);
    } else if (isBidAccepted) {
      cardBorderColor = Colors.amber.withOpacity(0.6);
    } else {
      cardBorderColor = AppColors.accent.withOpacity(0.5);
    }

    final badgeColor = isChatMessage
        ? const Color(0xFF25D366)
        : (isBidAccepted ? Colors.amber : AppColors.accent);

    final typeIcon = isChatMessage
        ? Icons.chat_rounded
        : (isBidAccepted ? Icons.celebration_rounded : Icons.local_offer_rounded);

    return Container(
      decoration: BoxDecoration(
        color: isRead ? AppColors.cardDark : const Color(0xFF1E2638),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: isRead ? 1 : 1.5,
        ),
        boxShadow: [
          if (!isRead)
            BoxShadow(
              color: badgeColor.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isChatMessage) {
              final senderId = metadata?['senderId'] ?? '';
              final senderName = metadata?['senderName'] ?? 'المستخدم';
              final contractId = metadata?['contractId'];
              final tripRequestId = metadata?['tripRequestId'];
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(
                    receiverId: senderId,
                    receiverName: senderName,
                    contractId: contractId,
                    tripRequestId: tripRequestId,
                  ),
                ),
              );
            } else if (isBidAccepted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DriverScheduleAndContractsScreen(),
                ),
              );
            } else if (tripId != null && tripId.toString().isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TripOffersScreen(tripId: tripId.toString()),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Type icon + Title + Time ago
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        typeIcon,
                        color: badgeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (timeAgo.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              timeAgo,
                              style: const TextStyle(fontSize: 11, color: Colors.white38),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isBidAccepted && driverEarnings != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success.withOpacity(0.5)),
                        ),
                        child: Text(
                          '$driverEarnings ر.س صافي',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else if (offerPrice != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                        ),
                        child: Text(
                          '$offerPrice ر.س',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Message description
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),

                // Car details & interior photo preview box (if bid notification)
                if (hasInteriorPhoto || carFullName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        if (hasInteriorPhoto)
                          GestureDetector(
                            onTap: () => _showImageDialog(
                              context,
                              carPhotoInteriorUrl,
                              'صورة مقصورة سيارة $carFullName من الداخل',
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    carPhotoInteriorUrl.startsWith('http')
                                        ? carPhotoInteriorUrl
                                        : '${ApiEndpoints.baseDomain}$carPhotoInteriorUrl',
                                    width: 72,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 72,
                                      height: 52,
                                      color: Colors.white10,
                                      child: const Icon(Icons.airline_seat_recline_normal_rounded, color: Colors.white38, size: 28),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (carFullName.isNotEmpty)
                                Text(
                                  carFullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              if (driverName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'الكابتن: $driverName',
                                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                                    ),
                                    if (driverRating != null) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                      Text(
                                        ' $driverRating',
                                        style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              const Text(
                                'انقر لمعاينة الصورة المكبرة وتفاصيل العرض',
                                style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action bar
                if (isChatMessage) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final senderId = metadata?['senderId'] ?? '';
                        final senderName = metadata?['senderName'] ?? 'المستخدم';
                        final contractId = metadata?['contractId'];
                        final tripRequestId = metadata?['tripRequestId'];
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              receiverId: senderId,
                              receiverName: senderName,
                              contractId: contractId,
                              tripRequestId: tripRequestId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                      label: const Text('فتح المحادثة والرد الآن'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ] else if (isBidAccepted) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DriverScheduleAndContractsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                      label: const Text('الانتقال إلى جدول عملي اليومي وعقودي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ] else if (tripId != null && tripId.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TripOffersScreen(tripId: tripId.toString()),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('معاينة العرض وتفاصيل السيارة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
