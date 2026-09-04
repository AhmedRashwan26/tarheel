import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'client_login_screen.dart';
import 'driver_register_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header with logo branding
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car_filled_rounded,
                        color: AppColors.accent,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'مرحباً بك في ترحيل',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'اختر نوع الحساب للمتابعة',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Option 1: Client Card
              _buildRoleCard(
                context,
                title: 'أنا راكب / عميل',
                subtitle: 'نشر مشاوير مجدولة (يومية، أسبوعية، شهرية)، استلام عروض الأسعار، ودفع آمن عبر ضمان ترحيل.',
                icon: Icons.person_pin_circle_rounded,
                badgeText: 'تسجيل بالجوال أو البريد',
                badgeColor: AppColors.secondary,
                accentColor: AppColors.primary,
                onTap: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  auth.setRole('CLIENT');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ClientLoginScreen()),
                  );
                },
              ),

              const SizedBox(height: 18),

              // Option 2: Driver Card
              _buildRoleCard(
                context,
                title: 'أنا سائق / كابتن',
                subtitle: 'تصفح طلبات المشاوير، تقديم عروض الأسعار، واستلام أرباحك الصافية (90%) مباشرة على حسابك البنكي.',
                icon: Icons.local_taxi_rounded,
                badgeText: 'عمولة 10% + تحويل بنكي',
                badgeColor: AppColors.accent,
                accentColor: AppColors.accent,
                onTap: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  auth.setRole('DRIVER');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DriverRegisterScreen()),
                  );
                },
              ),

              const Spacer(),

              // Anti-cash policy note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.escrowLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.escrow.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.escrow, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'جميع الرحلات محمية بضمان ترحيل المالي وتخضع لضريبة القيمة المضافة 15%.',
                        style: TextStyle(fontSize: 11, color: AppColors.escrow, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accentColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
