import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';

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
    final priceController = TextEditingController(text: '1000');
    final notesController = TextEditingController(text: 'سيارة حديثة ومكيفة، ملتزم بالمواعيد المحددة.');
    double enteredPrice = 1000.0;
    double platformCommission = 100.0; // 10%
    double netEarnings = 900.0; // 90%

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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Text(
                  'المسار: ${trip['pickupAddress']} ➔ ${trip['dropoffAddress']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'سعر العرض الإجمالي المقترح (ريال سعودي)',
                    prefixIcon: Icon(Icons.payments_rounded, color: AppColors.accent),
                  ),
                  onChanged: (val) {
                    final p = double.tryParse(val) ?? 0.0;
                    setModalState(() {
                      enteredPrice = p;
                      platformCommission = p * 0.10;
                      netEarnings = p - platformCommission;
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
                          const Text('عمولة منصة ترحيل (10%):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('-$platformCommission ر.س', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.cardBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('صافي أرباحك المحولة لحسابك البنكي (90%):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(
                            '$netEarnings ر.س',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.success),
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
                    labelText: 'ملاحظات العرض ومواصفات سيارتك',
                    prefixIcon: Icon(Icons.note_alt_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final tripProvider = Provider.of<TripProvider>(context, listen: false);
                    final success = await tripProvider.submitDriverOffer(
                      tripRequestId: trip['id'],
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
        title: const Text('سوق طلبات المشاوير المفتوحة'),
      ),
      body: RefreshIndicator(
        onRefresh: () => tripProvider.fetchOpenTripsFeed(),
        child: tripProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : tripProvider.openTripsFeed.isEmpty
                ? const Center(child: Text('لا توجد طلبات مشاوير جديدة متاحة حالياً'))
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trip['frequency'] == 'MONTHLY'
                      ? '🗓️ تعاقد شهري'
                      : trip['frequency'] == 'WEEKLY'
                          ? '📅 تعاقد أسبوعي'
                          : '⚡ مشوار مرة واحدة',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${trip['passengersCount'] ?? 1} ركاب',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route Details
          Row(
            children: [
              const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip['pickupAddress'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip['dropoffAddress'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.cardBorder),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'وقت الذهاب: ${trip['preferredTime'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (trip['hasReturn'] == true)
                Text(
                  'العودة: ${trip['returnTime'] ?? ''}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
            ],
          ),
          const SizedBox(height: 14),

          ElevatedButton.icon(
            onPressed: () => _showSubmitBidDialog(trip),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.local_offer_rounded, size: 18),
            label: const Text('تقديم عرض سعر لهذا المشوار'),
          ),
        ],
      ),
    );
  }
}
