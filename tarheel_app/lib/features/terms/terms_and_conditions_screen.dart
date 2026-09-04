import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الشروط والأحكام'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: AppColors.primary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'وثيقة الشروط والأحكام وسياسات الاستخدام الرسمية لمنصة «تـرحـيـل»',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '1. أحكام عامة',
              content:
                  'منصة «ترحيل» هي منصة وساطة تقنية لجدولة وتنظيم الرحلات والمشاوير بين الركاب والسائقين المعتمدين في المملكة العربية السعودية. باستخدامك للتطبيق فإنك توافق على الالتزام بكافة البنود والشروط الموضحة أدناه.',
            ),

            _buildSection(
              title: '2. سياسة عمولة المنصة والسداد',
              content:
                  '• تخصم منصة ترحيل عمولة بنسبة 10% فقط من القيمة الإجمالية لكل رحلة مكتملة.\n'
                  '• يتم تحويل صافي أرباح السائق (90%) مباشرة إلى الحساب البنكي المسجل والموثق برقم الآيبان (IBAN) بعد انتهاء المشوار وتأكيد العميل.\n'
                  '• تخضع جميع المدفوعات لضريبة القيمة المضافة المقررة بنسبة 15% (VAT).',
            ),

            _buildSection(
              title: '3. الضمان المالي وحظر التعامل النقدي (Anti-Cash Policy)',
              content:
                  '• للحفاظ على حقوق الطرفين وسلامة المعاملات، تتم جميع الحجوزات عبر نظام الضمان المالي (Escrow) داخل التطبيق.\n'
                  '• يمنع منعاً باتاً طلب أو دفع أي مبالغ نقدية أو تحويلات خارج التطبيق.\n'
                  '• أي اتفاق يتم خارج المنصة يلغي الضمان المالي ويعرض حساب السائق أو العميل للحظر الدائم والمساءلة النظامية.',
            ),

            _buildSection(
              title: '4. التزامات الكابتن / السائق',
              content:
                  '• الالتزام بالمواعيد المحددة مع الركاب.\n'
                  '• الحفاظ على نظافة المركبة والتأكد من عمل نظام التكييف (A/C) بكفاءة عالية.\n'
                  '• سريان رخصة القيادة، استمارة المركبة، والتأمين المعتمد طوال فترة تقديم الخدمة.\n'
                  '• الالتزام بأنظمة المرور والسلامة المعمول بها في المملكة العربية السعودية.',
            ),

            _buildSection(
              title: '5. سياسة الإلغاء والاسترجاع',
              content:
                  '• يحق للعميل استرداد أمواله المحجوزة في الضمان في حال تعذر تقديم الخدمة من قبل السائق أو الإخلال بالموعد المتفق عليه.\n'
                  '• يتم البت في أي نزاع مالي عبر فريق الدعم وخدمة العملاء على مدار الساعة.',
            ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('فهمت وموافق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
        ],
      ),
    );
  }
}
