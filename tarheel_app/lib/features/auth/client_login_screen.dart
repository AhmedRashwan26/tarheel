import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';
import 'widgets/google_sign_in_button.dart';
import '../terms/terms_and_conditions_screen.dart';

class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key});

  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen> {
  final _loginIdentifierController = TextEditingController();
  String _selectedChannel = 'WHATSAPP'; // 'WHATSAPP', 'EMAIL'
  bool _isLoading = false;

  @override
  void dispose() {
    _loginIdentifierController.dispose();
    super.dispose();
  }

  void _onLoginIdentifierChanged(String value) {
    setState(() {
      final text = value.trim();
      if (text.contains('@')) {
        _selectedChannel = 'EMAIL';
      } else if (text.isNotEmpty && RegExp(r'^[0-9+]+$').hasMatch(text)) {
        if (_selectedChannel == 'EMAIL') {
          _selectedChannel = 'WHATSAPP';
        }
      }
    });
  }

  Future<void> _handleLogin() async {
    final identifier = _loginIdentifierController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الجوال أو البريد الإلكتروني')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.setRole('CLIENT');
    final success = await auth.sendOtp(identifier, channel: _selectedChannel, role: 'CLIENT');
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            identifier: identifier,
            isRegistration: false,
            role: 'CLIENT',
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
        title: const Text('دخول الركاب والعملاء'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // Logo Header
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 105,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'حياك الله في تـرحـيـل',
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
                  'سجّل دخولك برقم جوالك أو بريدك الإلكتروني للمتابعة فوراً',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 30),

              // Identifier Input
              TextField(
                controller: _loginIdentifierController,
                keyboardType: TextInputType.emailAddress,
                onChanged: _onLoginIdentifierChanged,
                decoration: const InputDecoration(
                  labelText: 'رقم الجوال أو البريد الإلكتروني',
                  hintText: '+9665xxxxxxxx أو name@email.com',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),

              // Channel Selector
              const Text(
                'قناة استلام رمز التحقق (OTP):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: _buildChannelChip('WHATSAPP', 'عبر الواتساب', Icons.chat_bubble_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildChannelChip('EMAIL', 'عبر الإيميل', Icons.email_rounded)),
                ],
              ),

              const SizedBox(height: 28),

              // Send OTP Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('إرسال رمز التحقق (OTP)'),
              ),

              const SizedBox(height: 22),

              // Divider "أو"
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'أو',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 18),

              // Google Sign-In Button
              const GoogleSignInButton(role: 'CLIENT'),

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
                          const TextSpan(text: 'بالدخول واستخدام المنصة، فإنك توافق على '),
                          TextSpan(
                            text: 'الشروط والأحكام',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' وسياسة عدم التعامل النقدي.'),
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

  Widget _buildChannelChip(String value, String label, IconData icon) {
    final isSelected = _selectedChannel == value;
    return InkWell(
      onTap: () => setState(() => _selectedChannel = value),
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
