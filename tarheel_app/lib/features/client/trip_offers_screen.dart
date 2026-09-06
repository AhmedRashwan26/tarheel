import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
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

          // Interior Car Photo Preview Card
          GestureDetector(
            onTap: () => _showVehiclePhotosDialog(context, vehicle, driverUser),
            child: Container(
              height: 155,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildVehicleImage(vehicle['photoInteriorUrl']),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.airline_seat_recline_normal_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'صورة مقصورة السيارة من الداخل',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'معاينة مقصورة السيارة والفرش الداخلي 💺',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

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

  Widget _buildVehicleImage(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.airline_seat_recline_normal_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 6),
            Text('صورة المقصورة الداخلية غير مرفوعة', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    final fullUrl = rawUrl.startsWith('http') ? rawUrl : '${ApiEndpoints.baseDomain}$rawUrl';

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey.shade400),
              const SizedBox(height: 4),
              Text('صورة مقصورة السيارة من الداخل', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        );
      },
    );
  }

  void _showVehiclePhotosDialog(BuildContext context, Map<String, dynamic> vehicle, Map<String, dynamic> driverUser) {
    final photos = [
      {
        'title': 'مقصورة السيارة والمقاعد والفرش الداخلي',
        'url': vehicle['photoInteriorUrl'],
        'icon': Icons.airline_seat_recline_normal_rounded,
        'subtitle': 'تتيح لك التأكد من نظافة المقاعد، الفرش الداخلي، وجاهزية التكييف لراحة المشوار',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 45, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معاينة سيارة الكابتن ${driverUser['fullName'] ?? ''}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Text(
                        '${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''} ${vehicle['year'] ?? ''} (لوحة: ${vehicle['plateNumber'] ?? '---'})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Privacy & Safety Guarantee Notice
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'لحماية خصوصية وأمان الجميع، تقتصر معاينة العميل على صورة مقصورة السيارة من الداخل للتأكد من الراحة والنظافة، بينما تم فحص واعتماد صور زوايا السيارة الخارجية ورخصة القيادة والاستمارة رسمياً من قِبل إدارة المنصة.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.4, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final item = photos[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(item['icon'] as IconData, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              if (item['subtitle'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item['subtitle'] as String,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          child: SizedBox(
                            height: 230,
                            child: _buildVehicleImage(item['url'] as String?),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
