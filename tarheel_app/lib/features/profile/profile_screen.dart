import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../support/support_hub_screen.dart';
import '../auth/role_selection_screen.dart';

import '../../core/services/upload_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickAndUploadPhoto(BuildContext context, bool isDriver) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 12),
                  Text('جاري رفع الصورة الشخصية إلى الخادم...'),
                ],
              ),
              duration: Duration(seconds: 15),
            ),
          );
        }

        final uploadRes = await UploadService().uploadFile(file);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (uploadRes.success && uploadRes.url != null) {
          if (!context.mounted) return;
          await context.read<AuthProvider>().updateProfileAvatar(uploadRes.url!);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 تم رفع وتحديث الصورة الشخصية بنجاح: ${file.name}'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploadRes.errorMessage ?? 'فشل رفع الصورة الشخصية'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Avatar picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isDriver = auth.userRole == 'DRIVER';
    final driverProfile = user?['driverProfile'];
    final vehicle = driverProfile?['vehicle'];
    final avatarUrl = user?['avatarUrl'] ?? user?['profilePictureUrl'] ?? driverProfile?['profilePictureUrl'];
    final hasAvatar = avatarUrl != null && avatarUrl.toString().trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي والحساب'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.white),
            tooltip: 'مركز الدعم',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportHubScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Interactive Avatar with Camera Upload Badge
                  GestureDetector(
                    onTap: () => _pickAndUploadPhoto(context, isDriver),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDriver && !hasAvatar ? Colors.amberAccent : Colors.white,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: AppColors.surface,
                            child: hasAvatar
                                ? ClipOval(
                                    child: Image.network(
                                      UploadService.formatUrl(avatarUrl),
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 48, color: AppColors.primary),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Text(
                                    (user?['fullName'] ?? 'U')[0],
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDriver ? AppColors.accent : AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Avatar Action Label
                  TextButton.icon(
                    onPressed: () => _pickAndUploadPhoto(context, isDriver),
                    icon: Icon(
                      Icons.photo_camera_rounded,
                      size: 15,
                      color: isDriver && !hasAvatar ? Colors.amberAccent : Colors.white70,
                    ),
                    label: Text(
                      isDriver
                          ? (hasAvatar ? 'تعديل الصورة الشخصية' : 'رفع الصورة الشخصية (إجباري للسائق) ⚠️')
                          : (hasAvatar ? 'تعديل الصورة الشخصية' : 'إضافة صورة شخصية (اختياري للراكب)'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDriver && !hasAvatar ? Colors.amberAccent : Colors.white70,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    user?['fullName'] ?? 'المستخدم',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?['phone'] ?? user?['email'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 10),

                  // Role & Verification Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDriver
                          ? (driverProfile?['isVerified'] == true
                              ? AppColors.success.withValues(alpha: 0.25)
                              : AppColors.warning.withValues(alpha: 0.25))
                          : AppColors.secondary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDriver
                            ? (driverProfile?['isVerified'] == true
                                ? AppColors.success
                                : AppColors.warning)
                            : AppColors.secondary,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDriver ? Icons.verified : Icons.account_circle,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDriver
                              ? (driverProfile?['isVerified'] == true
                                  ? 'سائق موثق ومعتمد'
                                  : 'سائق - بانتظار اعتماد الوثائق')
                              : 'عميل معتمد ترحيل',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Mandatory Photo Alert Banner for Drivers without avatar
            if (isDriver && !hasAvatar) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade300, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الصورة الشخصية للكابتن إلزامية ⚠️',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'يلزم رفع صورة شخصية واضحة للتحقق من هويتك لدى الركاب وتمكين قبول العروض.',
                              style: TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => _pickAndUploadPhoto(context, isDriver),
                        child: const Text('رفع الآن', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Financial Escrow / Wallet Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.escrowLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.account_balance_wallet,
                                    color: AppColors.escrow),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isDriver
                                        ? 'إجمالي الأرباح المكتملة'
                                        : 'رصيد المحفظة / المبالغ المعلقة',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12),
                                  ),
                                  Text(
                                    '${user?['wallet']?['balance'] ?? '0.00'} ر.س',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.escrow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock,
                                    size: 14, color: AppColors.escrow),
                                SizedBox(width: 4),
                                Text(
                                  'ضمان ترحيل المالي',
                                  style: TextStyle(
                                      color: AppColors.escrow,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isDriver) ...[
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الحساب البنكي المسجل للتحويل:',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Text(
                              driverProfile?['bankName'] ?? 'مصرف الراجحي',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('رقم الآيبان (IBAN):',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Text(
                              driverProfile?['ibanNumber'] ??
                                  'SA******************',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.textPrimary),
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            if (isDriver && vehicle != null) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.directions_car, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text('بيانات المركبة المعتمدة',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primary)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''} (${vehicle['year'] ?? ''})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: vehicle['hasAirConditioning'] == true
                                    ? AppColors.secondaryLight
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.ac_unit,
                                      size: 14,
                                      color:
                                          vehicle['hasAirConditioning'] == true
                                              ? AppColors.secondary
                                              : Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    vehicle['hasAirConditioning'] == true
                                        ? 'مكيفة بالكامل'
                                        : 'بدون تكييف',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          vehicle['hasAirConditioning'] == true
                                              ? AppColors.secondary
                                              : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'سعة المقاعد: ${vehicle['capacity'] ?? 4} ركاب | اللون: ${vehicle['color'] ?? 'أبيض'}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Settings & Actions List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.support_agent,
                          color: AppColors.primary),
                      title: const Text('مركز المساعدة وخدمة العملاء',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SupportHubScreen()));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined,
                          color: AppColors.primary),
                      title: const Text('شروط الخدمة وضمان ترحيل المالي',
                          style: TextStyle(fontSize: 14)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('ضمان ترحيل وسياسة منع الكاش'),
                            content: const Text(
                              '• تخضع جميع الرحلات للضمان المالي الكامل (Escrow).\n'
                              '• يمنع منعاً باتاً التعامل النقدي المباشر أو الالتفاف على المنصة للحفاظ على الأمان والتأمين وتفادي حظر الحساب النهائي.\n'
                              '• يتم تحويل مستحقات السائق عند انتهاء مدة التعاقد وتقييمك له.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('فهمت ذلك'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.error),
                      title: const Text('تسجيل الخروج',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.error,
                              fontWeight: FontWeight.bold)),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('تسجيل الخروج'),
                            content: const Text(
                                'هل أنت متأكد من رغبتك في تسجيل الخروج من تطبيق ترحيل؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('إلغاء'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('تأكيد الخروج',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          final nav = Navigator.of(context);
                          await context.read<AuthProvider>().logout();
                          nav.pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const RoleSelectionScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logo Branding Footer
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 55,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'منصة تـرحـيـل للمشاوير المجدولة - إصدار 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
