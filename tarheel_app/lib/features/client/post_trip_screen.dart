import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';

class PostTripScreen extends StatefulWidget {
  final VoidCallback? onTripCreated;
  const PostTripScreen({super.key, this.onTripCreated});

  @override
  State<PostTripScreen> createState() => _PostTripScreenState();
}

class _PostTripScreenState extends State<PostTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final _pickupAddressController = TextEditingController(text: 'حي النرجس، شمال الرياض');
  final _dropoffAddressController = TextEditingController(text: 'جامعة الملك سعود، الدرعية');
  final _preferredTimeController = TextEditingController(text: '07:30');
  final _returnTimeController = TextEditingController(text: '15:30');
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  bool _hasReturn = true;
  String _frequency = 'MONTHLY'; // 'ONCE', 'WEEKLY', 'MONTHLY', 'CUSTOM_DAYS'
  int _passengersCount = 1;
  String _recurringDays = 'الأحد,الاثنين,الثلاثاء,الأربعاء,الخميس';

  bool _isLoading = false;

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _dropoffAddressController.dispose();
    _preferredTimeController.dispose();
    _returnTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePostTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasReturn && _returnTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد وقت العودة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final tripData = {
      'pickupAddress': _pickupAddressController.text.trim(),
      'pickupLatitude': 24.82345,
      'pickupLongitude': 46.68345,
      'dropoffAddress': _dropoffAddressController.text.trim(),
      'dropoffLatitude': 24.71612,
      'dropoffLongitude': 46.61891,
      'startDate': _startDate.toIso8601String().split('T')[0],
      'preferredTime': _preferredTimeController.text.trim(),
      'hasReturn': _hasReturn,
      if (_hasReturn) 'returnTime': _returnTimeController.text.trim(),
      'frequency': _frequency,
      'recurringDays': _recurringDays,
      'passengersCount': _passengersCount,
      'notes': _notesController.text.trim(),
    };

    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final success = await tripProvider.createTripRequest(tripData);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 تم نشر طلب مشوارك بنجاح! يمكنك الآن استعراض العروض المقدمة.'),
          backgroundColor: AppColors.success,
        ),
      );
      if (widget.onTripCreated != null) {
        widget.onTripCreated!();
      } else if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tripProvider.errorMessage ?? 'فشل نشر المشوار'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نشر طلب مشوار مجدول'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('1. المسار ونقاط الانطلاق والوصول', Icons.route_rounded),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pickupAddressController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان ونقطة الانطلاق (من أين؟)',
                    prefixIcon: Icon(Icons.my_location_rounded, color: AppColors.primary),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'نقطة الانطلاق مطلوبة' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dropoffAddressController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان ونقطة الوصول (إلى أين؟)',
                    prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.accent),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'نقطة الوصول مطلوبة' : null,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('2. المواعيد وخيار العودة', Icons.access_time_filled_rounded),
                const SizedBox(height: 12),

                // Start Date Picker Tile
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                  title: const Text('تاريخ بداية المشوار', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd (EEEE)', 'ar').format(_startDate),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  trailing: const Icon(Icons.edit_calendar_rounded, color: AppColors.accent),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                ),
                const SizedBox(height: 12),

                // Preferred Departure Time
                TextFormField(
                  controller: _preferredTimeController,
                  decoration: const InputDecoration(
                    labelText: 'وقت الذهاب المفضل صباحاً/مساءً',
                    hintText: 'مثال: 07:30',
                    prefixIcon: Icon(Icons.schedule_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),

                // Round-trip Toggle Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('هل هناك رحلة عودة؟', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('تفعيل خيار التوصيل ذهاباً وإياباً'),
                    value: _hasReturn,
                    activeColor: AppColors.accent,
                    onChanged: (val) => setState(() => _hasReturn = val),
                  ),
                ),

                if (_hasReturn) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _returnTimeController,
                    decoration: const InputDecoration(
                      labelText: 'موعد ووقت العودة (الساعة كم؟)',
                      hintText: 'مثال: 15:30 أو 03:30 عصراً',
                      prefixIcon: Icon(Icons.update_rounded, color: AppColors.accent),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                _buildSectionHeader('3. تكرار المشوار وعدد الركاب', Icons.repeat_rounded),
                const SizedBox(height: 12),

                // Frequency Selector Buttons
                Row(
                  children: [
                    _buildFrequencyOption('MONTHLY', 'شهري 🗓️'),
                    const SizedBox(width: 8),
                    _buildFrequencyOption('WEEKLY', 'أسبوعي 📅'),
                    const SizedBox(width: 8),
                    _buildFrequencyOption('ONCE', 'مرة واحدة ⚡'),
                  ],
                ),
                const SizedBox(height: 14),

                // Passengers Count Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('عدد الركاب المطلوب نقلهم:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_passengersCount > 1) setState(() => _passengersCount--);
                          },
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                        ),
                        Text(
                          '$_passengersCount ركاب',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_passengersCount < 20) setState(() => _passengersCount++);
                          },
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات إضافية للسائقين',
                    hintText: 'مثال: سآخذ صديقي معي في طريقي.. أو سأتوقف قليلاً عند البقالة...',
                    prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary),
                  ),
                ),

                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handlePostTrip,
                  icon: const Icon(Icons.send_rounded),
                  label: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('نشر المشوار واستقبال العروض'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildFrequencyOption(String value, String label) {
    final isSelected = _frequency == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _frequency = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
