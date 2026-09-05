import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../client/client_main_screen.dart';
import '../driver/driver_main_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String identifier;
  final bool isRegistration;
  final String? role;

  const OtpVerificationScreen({
    super.key,
    required this.identifier,
    this.isRegistration = false,
    this.role,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final rawCode = _otpController.text.trim();
    final cleanCode = rawCode
        .replaceAll('٠', '0').replaceAll('١', '1').replaceAll('٢', '2')
        .replaceAll('٣', '3').replaceAll('٤', '4').replaceAll('٥', '5')
        .replaceAll('٦', '6').replaceAll('٧', '7').replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll(RegExp(r'[^0-9]'), '')
        .trim();

    if (cleanCode.isEmpty || cleanCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رمز التحقق المكون من 6 أرقام')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final targetRole = widget.role ?? auth.userRole;
    final success = await auth.verifyOtp(widget.identifier, cleanCode, role: targetRole);
    setState(() => _isLoading = false);

    if (success && mounted) {
      if (auth.isAdmin) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false,
        );
      } else {
        final isDriverMode = (targetRole == 'DRIVER') || (auth.userRole == 'DRIVER') || auth.isDriver;
        if (isDriverMode) {
          auth.setRole('DRIVER');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DriverMainScreen()),
            (route) => false,
          );
        } else {
          auth.setRole('CLIENT');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ClientMainScreen()),
            (route) => false,
          );
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'رمز التحقق غير صحيح'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.identifier.contains('@');

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من الحساب'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEmail ? Icons.mark_email_read_rounded : Icons.chat_bubble_outline_rounded,
                    size: 40,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'أدخل رمز التحقق (OTP)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEmail
                    ? 'تم إرسال رمز التحقق المكون من 6 أرقام إلى بريدك الإلكتروني:\n${widget.identifier}'
                    : 'تم إرسال رمز التحقق المكون من 6 أرقام عبر الواتساب إلى:\n${widget.identifier}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),

              // OTP Input field
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                  color: AppColors.primary,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '------',
                  prefixIcon: Icon(Icons.lock_clock_rounded, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('تأكيد وتسجيل الدخول'),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  auth.sendOtp(widget.identifier);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إعادة إرسال رمز التحقق بنجاح')),
                  );
                },
                child: const Text(
                  'لم يصلك الرمز؟ إعادة الإرسال',
                  style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
