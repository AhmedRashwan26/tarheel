import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';
import '../chat/chat_room_screen.dart';

class DriverScheduleAndContractsScreen extends StatefulWidget {
  const DriverScheduleAndContractsScreen({super.key});

  @override
  State<DriverScheduleAndContractsScreen> createState() => _DriverScheduleAndContractsScreenState();
}

class _DriverScheduleAndContractsScreenState extends State<DriverScheduleAndContractsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedDate;
  final Map<String, String> _tripExecutionStatus = {}; // tripSlotId -> status ('PENDING', 'ON_THE_WAY', 'PICKED_UP', 'COMPLETED')

  final List<String> _daysOfWeekArabic = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getDayName(DateTime date) {
    // DateTime.weekday: 1 = Monday, 7 = Sunday
    // In Arabic list: 0 = Sunday, 1 = Monday ... 6 = Saturday
    final int index = date.weekday % 7; // Sunday (7%7 = 0)
    return _daysOfWeekArabic[index];
  }

  // Parse time string e.g. "07:30 AM" or "04:15 PM" to comparable minutes from midnight
  int _parseTimeToMinutes(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM') || clean.contains('م');
      final isAm = clean.contains('AM') || clean.contains('ص');
      final parts = clean.replaceAll(RegExp(r'[^\d:]'), '').split(':');
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return hour * 60 + minute;
    } catch (_) {
      return 0;
    }
  }

  List<Map<String, dynamic>> _generateDailySchedule(List<dynamic> contracts, DateTime date) {
    final String currentDayName = _getDayName(date);
    final List<Map<String, dynamic>> slots = [];

    for (var contract in contracts) {
      final client = contract['client'] ?? {};
      final trip = contract['tripRequest'] ?? {};
      final List<dynamic> recurringDays = trip['recurringDays'] ?? ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];
      final frequency = trip['frequency'] ?? 'MONTHLY';

      // Check if this contract runs on the selected day
      bool runsToday = false;
      if (frequency == 'ONCE' || frequency == 'DAILY') {
        runsToday = true;
      } else {
        runsToday = recurringDays.contains(currentDayName) || recurringDays.isEmpty;
      }

      if (!runsToday) continue;

      final contractId = contract['id'] ?? 'contract_${slots.length}';
      final departureTime = trip['departureTime'] ?? trip['preferredTime'] ?? '07:30 AM';
      final isRoundTrip = trip['isRoundTrip'] == true || trip['hasReturn'] == true;
      final returnTime = trip['returnTime'] ?? '03:30 PM';

      // Morning Outbound Slot
      final outboundSlotId = '${contractId}_outbound';
      slots.add({
        'slotId': outboundSlotId,
        'contractId': contractId,
        'type': 'OUTBOUND',
        'typeLabel': 'رحلة الذهاب',
        'time': departureTime,
        'timeMinutes': _parseTimeToMinutes(departureTime),
        'clientName': client['fullName'] ?? 'عميل ترحيل',
        'clientPhone': client['phone'] ?? '0500000000',
        'clientId': contract['clientId'] ?? client['id'] ?? '',
        'title': trip['title'] ?? 'مشوار مجدول',
        'pickup': trip['pickupAddress'] ?? 'نقطة الانطلاق',
        'dropoff': trip['dropoffAddress'] ?? 'نقطة الوصول',
        'seats': trip['seatsCount'] ?? 1,
        'notes': trip['notes'] ?? '',
        'earningsPerTrip': ((double.tryParse('${contract['driverEarnings'] ?? '1200'}') ?? 1200.0) / 22 / (isRoundTrip ? 2 : 1)).toStringAsFixed(1),
        'status': _tripExecutionStatus[outboundSlotId] ?? 'PENDING',
      });

      // Afternoon/Evening Return Slot (if round trip)
      if (isRoundTrip) {
        final returnSlotId = '${contractId}_return';
        slots.add({
          'slotId': returnSlotId,
          'contractId': contractId,
          'type': 'RETURN',
          'typeLabel': 'رحلة العودة',
          'time': returnTime,
          'timeMinutes': _parseTimeToMinutes(returnTime),
          'clientName': client['fullName'] ?? 'عميل ترحيل',
          'clientPhone': client['phone'] ?? '0500000000',
          'clientId': contract['clientId'] ?? client['id'] ?? '',
          'title': trip['title'] ?? 'مشوار عودة مجدول',
          'pickup': trip['dropoffAddress'] ?? 'نقطة الانطلاق للعودة',
          'dropoff': trip['pickupAddress'] ?? 'نقطة الوصول للعودة',
          'seats': trip['seatsCount'] ?? 1,
          'notes': trip['notes'] ?? '',
          'earningsPerTrip': ((double.tryParse('${contract['driverEarnings'] ?? '1200'}') ?? 1200.0) / 22 / 2).toStringAsFixed(1),
          'status': _tripExecutionStatus[returnSlotId] ?? 'PENDING',
        });
      }
    }

    // Sort chronologically by time
    slots.sort((a, b) => (a['timeMinutes'] as int).compareTo(b['timeMinutes'] as int));
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final contracts = tripProvider.myContracts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('عقودي والجدول الزمني'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_today_rounded, size: 20),
              text: 'الجدول اليومي للمشاوير',
            ),
            Tab(
              icon: Icon(Icons.assignment_rounded, size: 20),
              text: 'كافة العقود المفتوحة',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyScheduleTab(contracts),
          _buildAllContractsTab(contracts),
        ],
      ),
    );
  }

  Widget _buildDailyScheduleTab(List<dynamic> contracts) {
    final dailySlots = _generateDailySchedule(contracts, _selectedDate);
    final completedCount = dailySlots.where((s) => s['status'] == 'COMPLETED').length;
    final totalDailyEarnings = dailySlots.fold<double>(
      0.0,
      (sum, slot) => sum + (double.tryParse('${slot['earningsPerTrip']}') ?? 0.0),
    );

    return RefreshIndicator(
      onRefresh: () => Provider.of<TripProvider>(context, listen: false).fetchMyContracts(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Interactive Week Date Selector
            _buildWeekDateBar(),

            const SizedBox(height: 18),

            // Daily Summary Card for the Driver
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1F447E)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, color: AppColors.accent, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'جدول مشاوير يوم ${_getDayName(_selectedDate)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${dailySlots.length} مشاوير مجدولة',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryMetric(
                        title: 'المنجز اليوم',
                        value: '$completedCount من ${dailySlots.length}',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                      ),
                      Container(width: 1, height: 35, color: Colors.white24),
                      _buildSummaryMetric(
                        title: 'الدخل اليومي التقديري',
                        value: '${totalDailyEarnings.toStringAsFixed(0)} ر.س',
                        icon: Icons.monetization_on_outlined,
                        color: Colors.white,
                      ),
                      Container(width: 1, height: 35, color: Colors.white24),
                      _buildSummaryMetric(
                        title: 'حالة الجاهزية',
                        value: 'نشط ومتاح 🟢',
                        icon: Icons.local_taxi_rounded,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'الجدول الزمني بالترتيب',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'مرتب حسب التوقيت ⏱️',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Daily Slots List or Empty Placeholder
            if (dailySlots.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy_rounded, size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 14),
                    Text(
                      'لا توجد مشاوير مجدولة ليوم ${_getDayName(_selectedDate)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'يمكنك استقبال عروض جديدة من سوق الطلبات لملء هذا اليوم.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dailySlots.length,
                itemBuilder: (context, index) {
                  final slot = dailySlots[index];
                  final isFirst = index == 0;
                  final isLast = index == dailySlots.length - 1;
                  return _buildDailySlotTimelineItem(slot, isFirst: isFirst, isLast: isLast);
                },
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekDateBar() {
    final now = DateTime.now();
    // Show 7 days starting from 2 days ago up to 4 days ahead
    final List<DateTime> days = List.generate(7, (i) => now.add(Duration(days: i - 1)));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((date) {
          final isSelected = _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;
          final isToday = now.year == date.year &&
              now.month == date.month &&
              now.day == date.day;

          return InkWell(
            onTap: () => setState(() => _selectedDate = date),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isToday ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isToday ? AppColors.accent : Colors.transparent),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _getDayName(date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isToday ? AppColors.accent : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isToday ? AppColors.accent : AppColors.textPrimary),
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailySlotTimelineItem(Map<String, dynamic> slot, {required bool isFirst, required bool isLast}) {
    final isOutbound = slot['type'] == 'OUTBOUND';
    final status = slot['status'] as String;
    final isCompleted = status == 'COMPLETED';
    final isOnTheWay = status == 'ON_THE_WAY';
    final isPickedUp = status == 'PICKED_UP';

    Color slotColor = isOutbound ? AppColors.primary : AppColors.secondary;
    if (isCompleted) slotColor = AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.4)
              : (isOnTheWay || isPickedUp ? AppColors.accent : AppColors.cardBorder),
          width: isOnTheWay || isPickedUp ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Time Badge, Type, Status & Estimated Earnings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: slotColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, size: 16, color: slotColor),
                          const SizedBox(width: 5),
                          Text(
                            slot['time'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: slotColor,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isOutbound ? AppColors.primary : AppColors.accent).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOutbound ? 'ذهب ↗️' : 'عودة ↘️',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOutbound ? AppColors.primary : AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withValues(alpha: 0.12)
                        : (isOnTheWay || isPickedUp ? AppColors.accent.withValues(alpha: 0.12) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCompleted
                        ? 'مكتمل ✅'
                        : (isPickedUp ? 'الراكب بالسيارة 🚗' : (isOnTheWay ? 'في الطريق ⏳' : 'مجدول 📅')),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? AppColors.success
                          : (isOnTheWay || isPickedUp ? AppColors.accent : AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Passenger Info & Trip Title
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot['clientName'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${slot['title']} • ${slot['seats']} ركاب',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Earnings Badge
                Text(
                  '~${slot['earningsPerTrip']} ر.س',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Route Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(Icons.radio_button_checked, size: 16, color: AppColors.primary),
                    Container(width: 2, height: 26, color: Colors.grey.shade300),
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.accent),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الانطلاق: ${slot['pickup']}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'الوصول: ${slot['dropoff']}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (slot['notes'] != null && slot['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ملاحظة العميل: ${slot['notes']}',
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Interactive Actions Bar
            Row(
              children: [
                // Chat button
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            contractId: slot['contractId'],
                            receiverName: slot['clientName'],
                            receiverId: slot['clientId'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primary),
                    label: const Text('محادثة', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(width: 8),

                // Change status button
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: isCompleted
                          ? Colors.grey.shade400
                          : (isOnTheWay ? AppColors.accent : (isPickedUp ? AppColors.success : AppColors.primary)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _showTripStatusUpdateDialog(slot);
                    },
                    icon: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : (isOnTheWay ? Icons.directions_car_filled_rounded : Icons.play_arrow_rounded),
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      isCompleted
                          ? 'المشوار مكتمل'
                          : (isPickedUp ? 'إنهاء المشوار' : (isOnTheWay ? 'صعود الراكب' : 'بدء التحرك')),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTripStatusUpdateDialog(Map<String, dynamic> slot) {
    final slotId = slot['slotId'];
    final currentStatus = slot['status'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_road_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'تحديث حالة مشوار: ${slot['clientName']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusActionTile(
              title: '1. في الطريق إلى نقطة الانطلاق 🚗',
              subtitle: 'إشعار الراكب بأنك تحركت نحوه',
              isSelected: currentStatus == 'ON_THE_WAY',
              onTap: () {
                setState(() => _tripExecutionStatus[slotId] = 'ON_THE_WAY');
                Provider.of<TripProvider>(context, listen: false).updateScheduleTripStatus(slotId, 'ON_THE_WAY');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال إشعار للراكب: الكابتن في الطريق إليك!')),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildStatusActionTile(
              title: '2. تم صعود الراكب وبدء المسار 🛣️',
              subtitle: 'تأكيد ركوب العميل وانطلاق الرحلة',
              isSelected: currentStatus == 'PICKED_UP',
              onTap: () {
                setState(() => _tripExecutionStatus[slotId] = 'PICKED_UP');
                Provider.of<TripProvider>(context, listen: false).updateScheduleTripStatus(slotId, 'PICKED_UP');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تأكيد صعود الراكب وبدء المشوار.')),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildStatusActionTile(
              title: '3. تم إنزال الراكب وإنهاء المشوار بنجاح ✅',
              subtitle: 'تسجيل اكتمال المشوار اليومي وحفظه بالجدول',
              isSelected: currentStatus == 'COMPLETED',
              onTap: () {
                setState(() => _tripExecutionStatus[slotId] = 'COMPLETED');
                Provider.of<TripProvider>(context, listen: false).updateScheduleTripStatus(slotId, 'COMPLETED');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 أحسنت! تم إنهاء المشوار اليومي بنجاح.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.accent : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildAllContractsTab(List<dynamic> contracts) {
    if (contracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_late_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 14),
            const Text(
              'لا توجد عقود نشطة حالياً',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'يمكنك تصفح سوق الطلبات وتقديم عروض أسعار للحصول على عقود جديدة.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Provider.of<TripProvider>(context, listen: false).fetchMyContracts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contracts.length,
        itemBuilder: (context, index) {
          final contract = contracts[index];
          final client = contract['client'] ?? {};
          final trip = contract['tripRequest'] ?? {};
          final isRoundTrip = trip['isRoundTrip'] == true || trip['hasReturn'] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                            Icon(Icons.shield_rounded, size: 14, color: AppColors.escrow),
                            SizedBox(width: 4),
                            Text(
                              'سارٍ ومؤمن بالضمان 🛡️',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.escrow),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${contract['driverEarnings'] ?? contract['baseAmount'] ?? '1200'} ر.س',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.success, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'الراكب: ${client['fullName'] ?? 'عميل ترحيل'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text('عنوان المشوار: ${trip['title'] ?? 'مشوار مجدول'}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('الذهاب: ${trip['departureTime'] ?? '07:30 AM'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      if (isRoundTrip) ...[
                        const SizedBox(width: 14),
                        const Icon(Icons.replay_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text('العودة: ${trip['returnTime'] ?? '03:30 PM'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            contractId: contract['id'] ?? '',
                            receiverName: client['fullName'] ?? 'الراكب',
                            receiverId: contract['clientId'] ?? client['id'] ?? '',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_rounded, size: 16),
                    label: const Text('محادثة الراكب (نص / صوت / موقع مباشر)'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
