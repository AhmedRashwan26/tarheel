import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'client_login_screen.dart';
import 'driver_auth_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Logo & App Name
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'حياك الله',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'اختر نوع الحساب للمتابعة',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Option 1: Client Card
              _buildCleanRoleCard(
                context,
                title: 'أنا راكب / عميل',
                icon: Icons.person_pin_circle_rounded,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primaryLight.withValues(alpha: 0.12),
                onTap: () {
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  auth.setRole('CLIENT');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ClientLoginScreen()),
                  );
                },
              ),

              const SizedBox(height: 18),

              // Option 2: Driver Card
              _buildCleanRoleCard(
                context,
                title: 'أنا سائق / كابتن',
                icon: Icons.local_taxi_rounded,
                iconColor: AppColors.accent,
                iconBgColor: AppColors.accent.withValues(alpha: 0.12),
                onTap: () {
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  auth.setRole('DRIVER');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DriverAuthScreen()),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Admin Portal Button
              TextButton.icon(
                onPressed: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  if (auth.isAuthenticated && auth.isAdmin) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    );
                  } else {
                    _showAdminLoginDialog(context);
                  }
                },
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 20, color: AppColors.primaryLight),
                label: const Text(
                  'بوابة الإدارة والتحكم (Admin Portal)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    final identifierCtrl = TextEditingController(text: '+966500000001');
    final otpCtrl = TextEditingController(text: '123456');
    bool otpSent = false;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('تسجيل دخول الإدارة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'الوصول خاص بإدارة المنصة والمشرفين فقط لمتابعة السائقين، خدمة العملاء، النزاعات والبث.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: identifierCtrl,
                enabled: !otpSent,
                decoration: const InputDecoration(
                  labelText: 'رقم الجوال أو البريد الإداري',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              if (otpSent) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: otpCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رمز التحقق (OTP)',
                    prefixIcon: Icon(Icons.lock_clock_rounded),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: isLoading
                  ? null
                  : () async {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      if (!otpSent) {
                        setDialogState(() => isLoading = true);
                        final success = await auth.sendOtp(identifierCtrl.text.trim(), role: 'ADMIN');
                        setDialogState(() {
                          isLoading = false;
                          if (success) otpSent = true;
                        });
                        if (!success && dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(
                              content: Text(auth.errorMessage ?? 'فشل إرسال الرمز للإدارة'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() => isLoading = true);
                        final success = await auth.verifyOtp(
                          identifierCtrl.text.trim(),
                          otpCtrl.text.trim(),
                          role: 'ADMIN',
                        );
                        setDialogState(() => isLoading = false);
                        if (success && dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                          );
                        } else if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(
                              content: Text(auth.errorMessage ?? 'رمز التحقق الإداري غير صحيح'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: Text(
                isLoading
                    ? 'جاري التحقق...'
                    : (otpSent ? 'دخول لوحة التحكم' : 'إرسال رمز الدخول'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanRoleCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
