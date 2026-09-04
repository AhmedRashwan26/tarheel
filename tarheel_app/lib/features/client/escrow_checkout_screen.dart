import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';
import 'client_main_screen.dart';

class EscrowCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> contractData;

  const EscrowCheckoutScreen({super.key, required this.contractData});

  @override
  State<EscrowCheckoutScreen> createState() => _EscrowCheckoutScreenState();
}

class _EscrowCheckoutScreenState extends State<EscrowCheckoutScreen> {
  String _selectedPaymentMethod = 'MADA'; // 'MADA', 'CARD', 'APPLE_PAY', 'STC_PAY'
  bool _acknowledgeAntiCashPolicy = false;
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    if (!_acknowledgeAntiCashPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب الإقرار بعدم التعامل النقدي للحفاظ على ضمان ترحيل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final contractId = widget.contractData['contractId'] ?? widget.contractData['contract']?['id'];

    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final success = await tripProvider.processEscrowPayment(
      contractId: contractId,
      paymentMethod: _selectedPaymentMethod,
      acknowledgeAntiCashPolicy: true,
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('تم الدفع وتفعيل الضمان!'),
            ],
          ),
          content: const Text(
            'تم حجز المبلغ بنجاح في "ضمان ترحيل" وتفعيل العقد. تم إشعار السائق بضرورة الالتزام بالموعد وموقع الانطلاق بدقة.\n\nرحلتك الآن مؤمنة بالكامل 100%.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ClientMainScreen()),
                  (route) => false,
                );
              },
              child: const Text('العودة للرئيسية وتتبع الرحلة'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tripProvider.errorMessage ?? 'فشل إتمام عملية الدفع'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.contractData['financialInvoice'] ?? {};
    final basePrice = invoice['baseTripPrice'] ?? widget.contractData['contract']?['baseAmount'] ?? 1000.0;
    final vatAmount = invoice['vatAmount'] ?? widget.contractData['contract']?['vatAmount'] ?? 150.0;
    final totalPrice = invoice['totalPayableByClient'] ?? widget.contractData['contract']?['totalPaidByClient'] ?? 1150.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدفع والضمان المالي'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Escrow Protection Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.escrow.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.white, size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'محمي بنظام ضمان ترحيل',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'المبلغ يبقى معلقاً في الضمان ولا يحول للسائق إلا بعد انتهاء مدة التوصيل وتقييمك له.',
                            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text('تفاصيل الفاتورة الرسمية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Invoice Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildInvoiceRow('أجرة التوصيل الأساسية (عرض السائق)', '$basePrice ر.س'),
                    const SizedBox(height: 8),
                    _buildInvoiceRow('ضريبة القيمة المضافة (15% VAT)', '$vatAmount ر.س', isVat: true),
                    const Divider(height: 20, color: AppColors.cardBorder),
                    _buildInvoiceRow(
                      'المبلغ الإجمالي المحتجز في الضمان',
                      '$totalPrice ر.س',
                      isBold: true,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text('اختر وسيلة الدفع الإلكتروني', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Payment Methods
              Row(
                children: [
                  _buildPaymentMethodOption('MADA', 'مدى mada', Icons.credit_card_rounded),
                  const SizedBox(width: 8),
                  _buildPaymentMethodOption('APPLE_PAY', 'Apple Pay', Icons.apple_rounded),
                  const SizedBox(width: 8),
                  _buildPaymentMethodOption('STC_PAY', 'STC Pay', Icons.account_balance_wallet_rounded),
                ],
              ),

              const SizedBox(height: 24),

              // Strict Anti-Cash Legal Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.report_problem_rounded, color: Colors.red.shade700, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'تنبيه أمني صارم ومهم جداً',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ليس مسموحاً دفع أية مبالغ مالية أو نقدية أو تحويل بنكي مباشر للسائق. إن أي دفع خارج التطبيق يلغي حقك في ضمان ترحيل ويعرض المعاملة للمخالفة.',
                      style: TextStyle(fontSize: 11, color: Colors.red.shade900, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'أقر وألتزم بعدم دفع أي مبالغ نقدية أو تحويل للسائق مباشرة لحفظ حقي في الضمان',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                      ),
                      value: _acknowledgeAntiCashPolicy,
                      activeColor: Colors.red.shade700,
                      onChanged: (val) => setState(() => _acknowledgeAntiCashPolicy = val ?? false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.lock_rounded, size: 20),
                label: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'تأكيد الدفع ($totalPrice ر.س) وتفعيل الضمان',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isBold = false, bool isVat = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isVat ? AppColors.secondary : AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: color ?? (isVat ? AppColors.secondary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(String value, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
