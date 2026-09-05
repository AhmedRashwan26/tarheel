import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/socket/socket_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/chat_provider.dart';
import 'driver_feed_screen.dart';
import 'driver_schedule_and_contracts_screen.dart';
import '../client/notifications_screen.dart';
import '../support/support_hub_screen.dart';
import '../profile/profile_screen.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _currentIndex = 0;
  StreamSubscription? _bidSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).fetchOpenTripsFeed();
      Provider.of<TripProvider>(context, listen: false).fetchMyContracts();
      Provider.of<ChatProvider>(context, listen: false).fetchUnreadCount();
    });

    _bidSubscription = SocketService().bidStream.listen((data) {
      if (mounted && (data['event'] == 'BID_ACCEPTED_ALERT' || data['contract'] != null)) {
        Provider.of<TripProvider>(context, listen: false).fetchMyContracts();
        _showBidAcceptedDialog(data);
      }
    });
  }

  @override
  void dispose() {
    _bidSubscription?.cancel();
    super.dispose();
  }

  void _showBidAcceptedDialog(Map<String, dynamic> data) {
    final contract = data['contract'] is Map<String, dynamic> ? data['contract'] : {};
    final pickup = data['pickup'] ?? contract['tripRequest']?['pickupAddress'] ?? 'نقطة الانطلاق';
    final dropoff = data['dropoff'] ?? contract['tripRequest']?['dropoffAddress'] ?? 'نقطة الوصول';
    final preferredTime = data['preferredTime'] ?? contract['tripRequest']?['preferredTime'] ?? 'في الموعد المحدد';
    final baseAmount = data['baseAmount'] ?? contract['baseAmount'] ?? contract['acceptedOffer']?['offerPrice'];
    final driverEarnings = data['driverEarnings'] ?? contract['driverEarnings'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.cardDark,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.celebration_rounded, color: Colors.amber, size: 48),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎉 تهانينا! وافق العميل على عرضك',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'مشوار: $pickup ⬅️ $dropoff',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 14),

              // Earnings Banner
              if (driverEarnings != null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'صافي أرباحك المقدرة:',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            '$driverEarnings ر.س',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (baseAmount != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'إجمالي قيمة العرض الأساسي:',
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                            Text(
                              '$baseAmount ر.س (خصم 13.50% عمولة)',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Directives & Guidelines Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: AppColors.accent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'توجيهات ترحيل لنجاح الرحلة ورفع تقييمك:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildGuidelineItem(
                      icon: Icons.alarm_on_rounded,
                      color: Colors.orangeAccent,
                      title: 'احترام مواعيد العمل والوقت',
                      subtitle: 'الالتزام التام بالموعد المحدد ($preferredTime) والتواجد قبل الموعد بوقت كافٍ.',
                    ),
                    const SizedBox(height: 10),
                    _buildGuidelineItem(
                      icon: Icons.cleaning_services_rounded,
                      color: Colors.lightBlueAccent,
                      title: 'نظافة المركبة وجاهزيتها',
                      subtitle: 'تأكد من نظافة السيارة ورائحتها المنعشة وعمل التكييف بكفاءة لراحة الراكب.',
                    ),
                    const SizedBox(height: 10),
                    _buildGuidelineItem(
                      icon: Icons.star_rate_rounded,
                      color: Colors.amber,
                      title: 'التعامل بأخلاق حسنة ولباقة',
                      subtitle: 'حسن المعاملة يضمن لك تقييم 5 نجوم ويفتح لك أولوية استلام عروض ومشاريع جديدة مستقبلاً.',
                    ),
                    const SizedBox(height: 10),
                    _buildGuidelineItem(
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.accent,
                      title: 'إضافة المشوار لجدولك اليومي',
                      subtitle: 'تمت إضافة المشوار تلقائياً إلى جدول عملك اليومي بالمنصة لمتابعته بسهولة.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() => _currentIndex = 1); // Switch to "عقودي والجدول"
                },
                icon: const Icon(Icons.assignment_turned_in_rounded),
                label: const Text('عرض المشوار في جدول عملي اليومي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسناً، فهمت ذلك ومستعد للرحلة', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const DriverFeedScreen(),
      const DriverScheduleAndContractsScreen(),
      _buildDriverWalletScreen(),
      const SupportHubScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'سوق الطلبات'),
          BottomNavigationBarItem(
            icon: Consumer<ChatProvider>(
              builder: (context, chat, _) {
                if (chat.unreadCount == 0) return const Icon(Icons.assignment_rounded);
                return Badge(
                  label: Text('${chat.unreadCount}'),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.assignment_rounded),
                );
              },
            ),
            label: 'عقودي والجدول',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'المحفظة والبنك'),
          const BottomNavigationBarItem(icon: Icon(Icons.support_agent_rounded), label: 'الدعم الفني'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
        ],
      ),
    );
  }

  Widget _buildDriverWalletScreen() {
    final auth = Provider.of<AuthProvider>(context);
    final driverProfile = auth.user?['driverProfile'] ?? {};
    final walletBalance = driverProfile['walletBalance'] ?? 4500.0;
    final pendingEscrow = driverProfile['pendingEscrowBalance'] ?? 0.0;
    final bankName = driverProfile['bankName'] ?? 'مصرف الراجحي';
    final iban = driverProfile['iban'] ?? 'SA0380000000608010167519';

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفظة والحساب البنكي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'الإشعارات والتنبيهات',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bank Card Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1E468A)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('أرباحك المكتملة والمحولة', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('عمولة 13.50% مخصومة', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$walletBalance ر.س',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('البنك المحول إليه', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          Text(bankName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('رقم الآيبان IBAN', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          Text(
                            iban.length > 12 ? '${iban.substring(0, 6)}...${iban.substring(iban.length - 4)}' : iban,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pending Escrow Balance Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.escrowLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.escrow.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock_rounded, color: AppColors.escrow, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مبالغ معلقة قيد التنفيذ في الضمان', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.escrow)),
                        Text('$pendingEscrow ر.س', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.escrow)),
                        const Text('تحول لحسابك البنكي فور انتهاء المشوار وتقييم الراكب.', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
