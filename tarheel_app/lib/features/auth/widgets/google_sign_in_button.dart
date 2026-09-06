import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../client/client_main_screen.dart';
import '../../driver/driver_main_screen.dart';
import '../link_phone_screen.dart';

class GoogleSignInButton extends StatefulWidget {
  final String role; // 'CLIENT' or 'DRIVER'
  final String? label;

  const GoogleSignInButton({
    super.key,
    required this.role,
    this.label,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;

  void _showGoogleAccountPrompt(BuildContext context) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            _buildGoogleGIcon(size: 24),
            const SizedBox(width: 10),
            const Text(
              'تسجيل الدخول عبر Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني لحساب Google للمتابعة والدخول الفوري:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'بريد Google الإلكتروني',
                hintText: 'name@gmail.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم (اختياري)',
                hintText: 'اسمك في حساب Google',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال بريد إلكتروني صحيح لحساب Google')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _performGoogleLogin(email, nameController.text.trim());
            },
            child: const Text('متابعة الدخول', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performGoogleLogin(String email, String fullName) async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final displayName = fullName.isNotEmpty ? fullName : email.split('@')[0];
    final success = await auth.loginWithGoogle(
      email: email,
      fullName: displayName,
      role: widget.role,
      avatarUrl: 'https://lh3.googleusercontent.com/a/default-user',
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      if (auth.isAdmin) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (_) => false,
        );
      } else if (!auth.hasVerifiedPhone) {
        // إذا لم يكن لديه رقم جوال موثق، نوجهه فوراً لشاشة ربط وتأكيد الجوال
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LinkPhoneScreen(role: widget.role),
          ),
          (_) => false,
        );
      } else if (widget.role == 'DRIVER') {
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
          content: Text(auth.errorMessage ?? 'فشل تسجيل الدخول بحساب Google'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  static Widget _buildGoogleGIcon({double size = 20}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.g_mobiledata_rounded, size: size * 1.5, color: const Color(0xFF4285F4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        side: BorderSide(color: Colors.grey.shade300, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
      ),
      onPressed: _isLoading ? null : () => _showGoogleAccountPrompt(context),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoogleGIcon(size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.label ?? 'المتابعة باستخدام حساب Google',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C4043),
                  ),
                ),
              ],
            ),
    );
  }
}
