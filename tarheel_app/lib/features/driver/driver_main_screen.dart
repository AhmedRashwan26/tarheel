import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import 'driver_feed_screen.dart';
import 'driver_schedule_and_contracts_screen.dart';
import '../support/support_hub_screen.dart';
import '../profile/profile_screen.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).fetchOpenTripsFeed();
      Provider.of<TripProvider>(context, listen: false).fetchMyContracts();
    });
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'سوق الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'عقودي والجدول'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'المحفظة والبنك'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_rounded), label: 'الدعم الفني'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
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
