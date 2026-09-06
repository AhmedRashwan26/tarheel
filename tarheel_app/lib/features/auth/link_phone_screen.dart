import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../client/client_main_screen.dart';
import '../driver/driver_main_screen.dart';

class LinkPhoneScreen extends StatefulWidget {
  final String? role;

  const LinkPhoneScreen({super.key, this.role});

  @override
  State<LinkPhoneScreen> createState() => _LinkPhoneScreenState();
}

class _LinkPhoneScreenState extends State<LinkPhoneScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;

  Timer? _resendTimer;
  int _resendCountdown = 60;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الجوال السعودي')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.sendBindPhoneOtp(rawPhone);
    setState(() => _isLoading = false);

    if (success && mounted) {
      setState(() => _otpSent = true);
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال رمز التحقق بنجاح عبر الواتساب'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'فشل إرسال رمز التحقق لرقم الجوال'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final rawPhone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رمز التحقق المكون من 6 أرقام')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.verifyAndBindPhone(rawPhone, otp);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 تم توثيق وربط رقم الجوال بنجاح! أهلاً بك في ترحيل'),
          backgroundColor: AppColors.success,
        ),
      );

      final targetRole = widget.role ?? auth.userRole;
      if (auth.isAdmin) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (_) => false,
        );
      } else if (targetRole == 'DRIVER' || auth.isDriver) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DriverMainScreen()),
          (_) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ClientMainScreen()),
          (_) => false,
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'رمز التحقق غير صحيح أو منتهي الصلاحية'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('توثيق وتأكيد رقم الجوال'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Visual Security Shield Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phonelink_lock_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'خطوة أخيرة: تأكيد رقم الجوال 📱',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'لإتمام تسجيل حسابك وتفعيل خدمات منصة ترحيل (نشر المشاوير، تقديم العروض، والتنسيق مع السائقين)، يجب ربط رقم جوال نشط برمز تحقق يصلك عبر الواتساب.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Phone Field Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'رقم الجوال (السعودية)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      enabled: !_otpSent,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: '05X XXX XXXX',
                        prefixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🇸🇦', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 6),
                              Text('+966', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (_otpSent) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'رمز التحقق (OTP)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: AppColors.primary,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '• • • • • •',
                          prefixIcon: const Icon(Icons.lock_clock_rounded, color: AppColors.primary),
                          hintStyle: TextStyle(letterSpacing: 8, color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _resendCountdown > 0 ? 'إعادة الإرسال خلال ($_resendCountdown ثانية)' : '',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: (_resendCountdown == 0 && !_isLoading) ? _handleSendOtp : null,
                            child: const Text('إعادة إرسال الرمز'),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : (_otpSent ? _handleVerifyOtp : _handleSendOtp),
                      child: Text(
                        _isLoading
                            ? 'جاري التحقق...'
                            : (_otpSent ? 'تأكيد وربط الرقم والبدء 🚀' : 'إرسال رمز التحقق عبر الواتساب'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Trust notice
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'رقم هاتفك محمي ومشفر ولا يتم مشاركته علناً في المنصة',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
