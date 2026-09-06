import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';
import 'widgets/google_sign_in_button.dart';
import '../terms/terms_and_conditions_screen.dart';

class DriverAuthScreen extends StatefulWidget {
  final int initialTabIndex;

  const DriverAuthScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DriverAuthScreen> createState() => _DriverAuthScreenState();
}

class _DriverAuthScreenState extends State<DriverAuthScreen> {
  final _loginPhoneController = TextEditingController();
  String _selectedLoginChannel = 'WHATSAPP';
  bool _isLoginLoading = false;

  @override
  void dispose() {
    _loginPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleDriverLogin() async {
    final phone = _loginPhoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الجوال أو البريد الإلكتروني')),
      );
      return;
    }

    setState(() => _isLoginLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.setRole('DRIVER');
    final success = await auth.sendOtp(phone, channel: _selectedLoginChannel, role: 'DRIVER');
    setState(() => _isLoginLoading = false);

    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            identifier: phone,
            isRegistration: false,
            role: 'DRIVER',
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'فشل إرسال رمز التحقق'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بوابة دخول الكباتن والسائقين'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // Header Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car_filled_rounded,
                    color: AppColors.primary,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'حياك الله يا كابتن!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'أدخل رقم جوالك أو بريدك الإلكتروني للدخول فوراً واستعراض سوق الطلبات',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _loginPhoneController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) {
                  final text = val.trim();
                  if (text.contains('@') && _selectedLoginChannel != 'EMAIL') {
                    setState(() => _selectedLoginChannel = 'EMAIL');
                  } else if (text.isNotEmpty && !text.contains('@') && _selectedLoginChannel != 'WHATSAPP') {
                    setState(() => _selectedLoginChannel = 'WHATSAPP');
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'رقم الجوال أو البريد الإلكتروني',
                  hintText: '+9665xxxxxxxx أو name@email.com',
                  prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'قناة استلام رمز التحقق (OTP):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: _buildLoginChannelChip('WHATSAPP', 'عبر الواتساب', Icons.chat_bubble_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildLoginChannelChip('EMAIL', 'عبر الإيميل', Icons.email_rounded)),
                ],
              ),

              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isLoginLoading ? null : _handleDriverLogin,
                child: _isLoginLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('إرسال رمز التحقق (OTP)'),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'أو',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.cardBorder)),
                ],
              ),

              const SizedBox(height: 18),

              const GoogleSignInButton(role: 'DRIVER'),

              const SizedBox(height: 36),

              // Terms & Conditions Footer Note
              Center(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                        children: [
                          const TextSpan(text: 'بالدخول، فإنك تقر وتوافق على '),
                          TextSpan(
                            text: 'الشروط والأحكام',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' وعمولة 13.50% وسياسة عدم التعامل النقدي.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginChannelChip(String value, String label, IconData icon) {
    final isSelected = _selectedLoginChannel == value;
    return InkWell(
      onTap: () => setState(() => _selectedLoginChannel = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
