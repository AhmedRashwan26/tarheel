import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class RateDriverDialog extends StatefulWidget {
  final String contractId;
  final String driverName;

  const RateDriverDialog({
    super.key,
    required this.contractId,
    required this.driverName,
  });

  @override
  State<RateDriverDialog> createState() => _RateDriverDialogState();
}

class _RateDriverDialogState extends State<RateDriverDialog> {
  final ApiClient _api = ApiClient();
  final TextEditingController _commentCtrl = TextEditingController();

  int _overallRating = 5;
  int _punctualityRating = 5;
  int _cleanlinessRating = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    setState(() => _isLoading = true);

    try {
      final response = await _api.post(
        ApiEndpoints.submitReview,
        data: {
          'contractId': widget.contractId,
          'rating': _overallRating,
          'punctualityRating': _punctualityRating,
          'cleanlinessRating': _cleanlinessRating,
          'comment': _commentCtrl.text.trim().isNotEmpty ? _commentCtrl.text.trim() : 'تجربة ممتازة وملتزمة بالمواعيد',
        },
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (response.data['success'] == true) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'فشل إرسال التقييم'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال التقييم بنجاح وشكراً لمساهمتك في رفع جودة الخدمة!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Widget _buildStarSelector(String title, int value, Function(int) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return IconButton(
              icon: Icon(
                starIndex <= value ? Icons.star_rounded : Icons.star_border_rounded,
                color: const Color(0xFFF59E0B),
                size: 32,
              ),
              onPressed: () => onSelected(starIndex),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: AppColors.accent, size: 48),
              ),
              const SizedBox(height: 14),

              // Title
              const Text(
                'تقييم الرحلة والسائق',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'الكابتن: ${widget.driverName}',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),

              // Criteria 1: Overall
              _buildStarSelector(
                'التقييم العام للرحلة:',
                _overallRating,
                (val) => setState(() => _overallRating = val),
              ),

              const SizedBox(height: 10),

              // Criteria 2: Punctuality
              _buildStarSelector(
                'الالتزام بالمواعيد والانطلاق:',
                _punctualityRating,
                (val) => setState(() => _punctualityRating = val),
              ),

              const SizedBox(height: 10),

              // Criteria 3: Cleanliness & AC
              _buildStarSelector(
                'نظافة المركبة وكفاءة التكييف (A/C):',
                _cleanlinessRating,
                (val) => setState(() => _cleanlinessRating = val),
              ),

              const SizedBox(height: 14),

              // Comment Field
              TextField(
                controller: _commentCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'اكتب تعليقك أو ملاحظاتك للكابتن...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                      child: const Text('لاحقاً', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              'إرسال التقييم',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
