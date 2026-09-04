import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';
import 'escrow_checkout_screen.dart';

class TripOffersScreen extends StatefulWidget {
  final String tripId;

  const TripOffersScreen({super.key, required this.tripId});

  @override
  State<TripOffersScreen> createState() => _TripOffersScreenState();
}

class _TripOffersScreenState extends State<TripOffersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).fetchTripDetails(widget.tripId);
    });
  }

  Future<void> _handleAcceptOffer(Map<String, dynamic> offer) async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final contractData = await tripProvider.acceptOffer(offer['id']);

    if (contractData != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EscrowCheckoutScreen(
            contractData: contractData,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tripProvider.errorMessage ?? 'فشل قبول العرض'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final trip = tripProvider.selectedTripDetails;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عروض الأسعار المقدمة'),
      ),
      body: tripProvider.isLoading || trip == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Trip Summary Card
                  _buildTripHeaderCard(trip),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'العروض المستلمة (${(trip['offers'] as List?)?.length ?? 0})',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const Text(
                        'اختر العرض الأنسب لك',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if ((trip['offers'] as List?)?.isEmpty ?? true)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.accent),
                          SizedBox(height: 12),
                          Text(
                            'طلبك منشور حالياً في سوق السائقين',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ستصلك إشعارات فورية بمجرد تقديم السائقين لعروض أسعارهم.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ...((trip['offers'] as List).map((offer) => _buildOfferCard(offer)).toList()),
                ],
              ),
            ),
    );
  }

  Widget _buildTripHeaderCard(Map<String, dynamic> trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trip['frequency'] == 'MONTHLY'
                      ? 'مشوار شهري'
                      : trip['frequency'] == 'WEEKLY'
                          ? 'مشوار أسبوعي'
                          : 'مشوار مرة واحدة',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              if (trip['hasReturn'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text('عودة: ${trip['returnTime'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.my_location_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip['pickupAddress'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 7),
            child: SizedBox(height: 10, child: VerticalDivider(color: Colors.white30, width: 2)),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip['dropoffAddress'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final driverProfile = offer['driverProfile'] ?? {};
    final driverUser = driverProfile['user'] ?? {};
    final vehicle = driverProfile['vehicle'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Driver Profile Row
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverUser['fullName'] ?? 'كابتن ترحيل',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          '${driverProfile['ratingAverage'] ?? 5.0}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${driverProfile['totalTripsCount'] ?? 0} رحلة مكتملة)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${offer['offerPrice']}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.accent),
                  ),
                  const Text('ريال سعودي', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.cardBorder),

          // Vehicle Specs
          Row(
            children: [
              _buildVehicleFeatureBadge(
                Icons.directions_car_rounded,
                '${vehicle['brand'] ?? 'سيارة'} ${vehicle['model'] ?? ''} ${vehicle['year'] ?? ''}',
              ),
              const SizedBox(width: 6),
              _buildVehicleFeatureBadge(
                Icons.ac_unit_rounded,
                vehicle['isAirConditioned'] == true ? 'مكيفة ❄️' : 'غير مكيفة',
                color: vehicle['isAirConditioned'] == true ? Colors.blue.shade700 : Colors.grey,
              ),
              const SizedBox(width: 6),
              _buildVehicleFeatureBadge(
                Icons.event_seat_rounded,
                '${vehicle['capacity'] ?? 4} مقاعد',
              ),
            ],
          ),

          if (offer['driverNotes'] != null && (offer['driverNotes'] as String).isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ملاحظات السائق: ${offer['driverNotes']}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _handleAcceptOffer(offer),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 18),
                SizedBox(width: 8),
                Text('قبول هذا العرض والانتقال للدفع والضمان'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleFeatureBadge(IconData icon, String text, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color ?? AppColors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color ?? AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
