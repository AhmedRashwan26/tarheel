import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import 'post_trip_screen.dart';
import 'trip_offers_screen.dart';
import '../chat/chat_room_screen.dart';
import '../support/support_hub_screen.dart';
import '../profile/profile_screen.dart';

class ClientMainScreen extends StatefulWidget {
  const ClientMainScreen({super.key});

  @override
  State<ClientMainScreen> createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).fetchMyTripRequests();
      Provider.of<TripProvider>(context, listen: false).fetchMyContracts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildClientHomeScreen(),
      PostTripScreen(onTripCreated: () => setState(() => _currentIndex = 2)),
      _buildMyTripsListScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'نشر مشوار'),
          BottomNavigationBarItem(icon: Icon(Icons.commute_rounded), label: 'مشاويري والعروض'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_rounded), label: 'خدمة العملاء'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
        ],
      ),
    );
  }

  Widget _buildClientHomeScreen() {
    final auth = Provider.of<AuthProvider>(context);
    final tripProvider = Provider.of<TripProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تـرحـيـل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await tripProvider.fetchMyTripRequests();
          await tripProvider.fetchMyContracts();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Hero Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أهلاً بك، ${auth.user?['fullName'] ?? 'عزيزنا الراكب'} 👋',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'مشاويرك المجدولة مؤمنة بالكامل',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: AppColors.accent, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentIndex = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: const Text('نشر طلب مشوار جديد الآن'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Active Contracts & Ongoing Rides
              const Text(
                'الرحلات والعقود النشطة تحت الضمان',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 10),

              if (tripProvider.myContracts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Center(
                    child: Text('لا توجد عقود نشطة حالياً. انشر مشوارك ليصلك أفضل عروض السائقين!'),
                  ),
                )
              else
                ...tripProvider.myContracts.map((c) => _buildContractCard(c)).toList(),

              const SizedBox(height: 24),

              // Recent Requests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'طلباتك بانتظار العروض',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: const Text('عرض الكل'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (tripProvider.myTrips.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Center(child: Text('لم تقم بنشر أي طلب مشوار بعد')),
                )
              else
                ...tripProvider.myTrips.take(3).map((t) => _buildTripRequestItem(t)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final driverUser = contract['driverProfile']?['user'] ?? {};
    final vehicle = contract['driverProfile']?['vehicle'] ?? {};
    final tripRequest = contract['tripRequest'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.escrow.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.escrow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.escrowLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 12, color: AppColors.escrow),
                    SizedBox(width: 4),
                    Text('سارٍ تحت ضمان ترحيل', style: TextStyle(color: AppColors.escrow, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text(
                '${contract['totalPaidByClient'] ?? contract['baseAmount']} ر.س',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'الكابتن: ${driverUser['fullName'] ?? 'سائق ترحيل'} (${vehicle['brand'] ?? 'سيارة'} ${vehicle['model'] ?? ''})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'من: ${tripRequest['pickupAddress'] ?? ''} إلى: ${tripRequest['dropoffAddress'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          contractId: contract['id'],
                          receiverName: driverUser['fullName'] ?? 'السائق',
                          receiverId: contract['driverProfile']?['userId'] ?? '',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: const Text('محادثة السائق (نص/صوت/موقع)', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripRequestItem(Map<String, dynamic> trip) {
    final offersCount = trip['_count']?['offers'] ?? (trip['offers'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.directions_car_rounded, color: AppColors.primary),
        ),
        title: Text(
          trip['pickupAddress'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إلى: ${trip['dropoffAddress'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$offersCount عروض مقدمة',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TripOffersScreen(tripId: trip['id'])),
          );
        },
      ),
    );
  }

  Widget _buildMyTripsListScreen() {
    final tripProvider = Provider.of<TripProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشاويري والعروض المستلمة'),
      ),
      body: RefreshIndicator(
        onRefresh: () => tripProvider.fetchMyTripRequests(),
        child: tripProvider.myTrips.isEmpty
            ? const Center(child: Text('لا توجد طلبات مشاوير حالياً'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tripProvider.myTrips.length,
                itemBuilder: (context, index) {
                  return _buildTripRequestItem(tripProvider.myTrips[index]);
                },
              ),
      ),
    );
  }
}
      ),
    );
  }
}
