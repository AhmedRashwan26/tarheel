import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';
import '../client/notifications_screen.dart';

class DriverFeedScreen extends StatefulWidget {
  const DriverFeedScreen({super.key});

  @override
  State<DriverFeedScreen> createState() => _DriverFeedScreenState();
}

class _DriverFeedScreenState extends State<DriverFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).fetchOpenTripsFeed();
    });
  }

  void _showSubmitBidDialog(Map<String, dynamic> trip) {
    final priceController = TextEditingController(text: '800');
    final notesController = TextEditingController(
        text: 'سيارة حديثة ومكيفة، ملتزم بالمواعيد المحددة.');
    double enteredPrice = 800.0;
    double platformCommission = 108.0; // 13.50%
    double netEarnings = 692.0; // 86.50%

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تقديم عرض سعر لمشوار',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Text(
                  'المسار: ${trip['pickupAddress'] ?? ''} ➔ ${trip['dropoffAddress'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'سعر العرض الإجمالي (ريال سعودي)',
                    prefixIcon:
                        Icon(Icons.payments_rounded, color: AppColors.accent),
                  ),
                  onChanged: (val) {
                    final p = double.tryParse(val) ?? 0.0;
                    setModalState(() {
                      enteredPrice = p;
                      platformCommission = double.parse((p * 0.135).toStringAsFixed(2));
                      netEarnings = double.parse((p - platformCommission).toStringAsFixed(2));
                    });
                  },
                ),
                const SizedBox(height: 14),

                // Live Financial Breakdown Preview
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('عمولة منصة ترحيل (13.50%):',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          Text('-$platformCommission ر.س',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error)),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.cardBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('صافي أرباحك المحولة لحسابك (86.50%):',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(
                            '$netEarnings ر.س',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.success),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات العرض للعميل ومواصفات سيارتك',
                    prefixIcon:
                        Icon(Icons.note_alt_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final tripProvider =
                        Provider.of<TripProvider>(context, listen: false);
                    final success = await tripProvider.submitDriverOffer(
                      tripRequestId: trip['id'] ?? '',
                      offerPrice: enteredPrice,
                      driverNotes: notesController.text.trim(),
                    );

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 تم إرسال عرض السعر للعميل بنجاح!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  child: const Text('تأكيد وإرسال العرض للعميل'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('سوق طلبات ترحيل'),
          ],
        ),
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
      body: RefreshIndicator(
        onRefresh: () => tripProvider.fetchOpenTripsFeed(),
        child: tripProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent))
            : tripProvider.openTripsFeed.isEmpty
                ? const Center(
                    child: Text('لا توجد طلبات مشاوير جديدة متاحة حالياً'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tripProvider.openTripsFeed.length,
                    itemBuilder: (context, index) {
                      final trip = tripProvider.openTripsFeed[index];
                      return _buildFeedTripCard(trip);
                    },
                  ),
      ),
    );
  }

  Widget _buildFeedTripCard(Map<String, dynamic> trip) {
    final isRoundTrip =
        trip['isRoundTrip'] == true || trip['hasReturn'] == true;
    final frequency = trip['frequency'] ?? 'ONCE';
    final departureTime =
        trip['departureTime'] ?? trip['preferredTime'] ?? '08:00 AM';
    final returnTime = trip['returnTime'] ?? '04:00 PM';
    final seatsCount = trip['seatsCount'] ?? trip['passengersCount'] ?? 1;

    String frequencyLabel = '⚡ مشوار مرة واحدة';
    if (frequency == 'DAILY') frequencyLabel = '🔄 تعاقد يومي';
    if (frequency == 'WEEKLY') frequencyLabel = '📅 تعاقد أسبوعي';
    if (frequency == 'MONTHLY') frequencyLabel = '🗓️ تعاقد شهري';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badges Header: Frequency, Round-Trip vs One-Way, Seats Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Frequency Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  frequencyLabel,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),

              // Trip Type (ذهاب فقط / ذهاب وعودة)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isRoundTrip
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isRoundTrip
                          ? Icons.sync_alt_rounded
                          : Icons.arrow_forward_rounded,
                      size: 13,
                      color:
                          isRoundTrip ? AppColors.accent : Colors.blue.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isRoundTrip ? 'ذهاب وعودة' : 'ذهاب فقط',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isRoundTrip
                            ? AppColors.accent
                            : Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              // Seats Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '$seatsCount ركاب',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Route: Pickup & Dropoff
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.radio_button_checked,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('نقطة الانطلاق (من):',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                          Text(
                            trip['pickupAddress'] ?? 'موقع الانطلاق',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      SizedBox(
                        height: 16,
                        child: VerticalDivider(
                            color: AppColors.cardBorder, thickness: 1.5),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('نقطة الوصول (إلى):',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                          Text(
                            trip['dropoffAddress'] ?? 'موقع الوصول',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Timings Section (وقت الذهاب ووقت العودة)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      'وقت الذهاب: $departureTime',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ],
                ),
                if (isRoundTrip)
                  Row(
                    children: [
                      const Icon(Icons.replay_rounded,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'العودة: $returnTime',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Client Notes (ملاحظات العميل للسائق)
          if (trip['notes'] != null && trip['notes'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD566)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.speaker_notes_rounded, size: 16, color: Color(0xFFD48806)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Color(0xFF59441B), fontFamily: 'Cairo', height: 1.4),
                        children: [
                          const TextSpan(
                            text: 'ملاحظة العميل للكابتن: ',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF874D00)),
                          ),
                          TextSpan(text: '${trip['notes']}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Bid Submission Button
          ElevatedButton.icon(
            onPressed: () => _showSubmitBidDialog(trip),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.local_offer_rounded, size: 18),
            label: const Text(
              'تقديم عرض سعر لهذا المشوار',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
