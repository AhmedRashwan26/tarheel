import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/support_provider.dart';

class SupportHubScreen extends StatefulWidget {
  const SupportHubScreen({super.key});

  @override
  State<SupportHubScreen> createState() => _SupportHubScreenState();
}

class _SupportHubScreenState extends State<SupportHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().fetchMyTickets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateTicketModal(BuildContext context, {String initialDept = 'CUSTOMER_SERVICE'}) {
    final formKey = GlobalKey<FormState>();
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String dept = initialDept;
    String category = dept == 'CUSTOMER_SERVICE' ? 'استفسار عن رحلة أو حجز' : 'مشكلة في التطبيق أو الحساب';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'فتح تذكرة مساعدة جديدة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Department Choice
                  const Text('القسم المختص:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('خدمة العملاء')),
                          selected: dept == 'CUSTOMER_SERVICE',
                          selectedColor: AppColors.primaryLight.withOpacity(0.2),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                dept = 'CUSTOMER_SERVICE';
                                category = 'استفسار عن رحلة أو حجز';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('الدعم الفني')),
                          selected: dept == 'TECHNICAL_SUPPORT',
                          selectedColor: AppColors.secondary.withOpacity(0.2),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                dept = 'TECHNICAL_SUPPORT';
                                category = 'مشكلة في التطبيق أو الحساب';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Category
                  const Text('التصنيف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: (dept == 'CUSTOMER_SERVICE'
                            ? [
                                'استفسار عن رحلة أو حجز',
                                'اعتراض مالي أو ضمان استرجاع',
                                'شكوى بخصوص سائق / عميل',
                                'أخرى',
                              ]
                            : [
                                'مشكلة في التطبيق أو الحساب',
                                'خطأ أثناء الدفع الإلكتروني',
                                'خلل في الإشعارات أو الموقع',
                                'أخرى',
                              ])
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),

                  const SizedBox(height: 14),

                  // Subject
                  const Text('عنوان التذكرة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: subjectCtrl,
                    decoration: InputDecoration(
                      hintText: 'مثال: مشكلة في تأكيد الضمان المالي',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال العنوان' : null,
                  ),

                  const SizedBox(height: 14),

                  // Description
                  const Text('تفاصيل المشكلة / الاستفسار:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'يرجى شرح التفاصيل بالكامل لمساعدتك بأسرع وقت...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال التفاصيل' : null,
                  ),

                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(ctx);
                          final success = await context.read<SupportProvider>().createSupportTicket(
                                department: dept,
                                subject: subjectCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                category: category,
                                priority: 'NORMAL',
                              );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? '✅ تم فتح تذكرة الدعم بنجاح! سيتم الرد عليك في أقرب وقت.'
                                      : '❌ فشل إرسال التذكرة، حاول مرة أخرى.',
                                ),
                                backgroundColor: success ? AppColors.success : AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'إرسال التذكرة لفريق الدعم',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final support = context.watch<SupportProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز المساعدة والدعم الفني'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.support_agent), text: 'خدمة العملاء'),
            Tab(icon: Icon(Icons.build_circle_outlined), text: 'الدعم التقني'),
          ],
        ),
      ),
      body: support.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTicketsList(support.myTickets.where((t) => t['department'] == 'CUSTOMER_SERVICE').toList(), 'CUSTOMER_SERVICE'),
                _buildTicketsList(support.myTickets.where((t) => t['department'] == 'TECHNICAL_SUPPORT').toList(), 'TECHNICAL_SUPPORT'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text(
          'تذكرة جديدة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _openCreateTicketModal(
          context,
          initialDept: _tabController.index == 0 ? 'CUSTOMER_SERVICE' : 'TECHNICAL_SUPPORT',
        ),
      ),
    );
  }

  Widget _buildTicketsList(List<dynamic> tickets, String dept) {
    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                dept == 'CUSTOMER_SERVICE' ? Icons.headset_mic_outlined : Icons.code,
                size: 70,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد تذاكر دعم حالياً',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                dept == 'CUSTOMER_SERVICE'
                    ? 'فريق خدمة عملاء ترحيل جاهز للإجابة على استفسارات الرحلات والضمان المالي على مدار الساعة.'
                    : 'فريق الدعم الفني جاهز لمساعدتك في أي استفسار أو مشكلة تقنية تواجهها.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<SupportProvider>().fetchMyTickets(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          final status = ticket['status'] ?? 'OPEN';
          final createdAt = ticket['createdAt'] != null
              ? DateFormat('yyyy/MM/dd - hh:mm a').format(DateTime.parse(ticket['createdAt']))
              : '';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: dept == 'CUSTOMER_SERVICE' ? AppColors.primaryLight.withOpacity(0.15) : AppColors.secondaryLight,
                child: Icon(
                  dept == 'CUSTOMER_SERVICE' ? Icons.support_agent : Icons.phonelink_setup,
                  color: dept == 'CUSTOMER_SERVICE' ? AppColors.primary : AppColors.secondary,
                ),
              ),
              title: Text(
                ticket['subject'] ?? 'تذكرة دعم',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusBadge(status),
                      const SizedBox(width: 8),
                      Text(
                        ticket['category'] ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(createdAt, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تفاصيل التذكرة:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ticket['description'] ?? '',
                        style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      if (ticket['replies'] != null && (ticket['replies'] as List).isNotEmpty) ...[
                        const Text(
                          'الردود:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent),
                        ),
                        const SizedBox(height: 8),
                        ...(ticket['replies'] as List).map((reply) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: reply['isStaff'] == true ? AppColors.secondaryLight : AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        reply['isStaff'] == true ? '🛡️ فريق الدعم' : 'أنت',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: reply['isStaff'] == true ? AppColors.secondary : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(reply['message'] ?? '', style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'OPEN':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        text = 'قيد المراجعة';
        break;
      case 'IN_PROGRESS':
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        text = 'جاري العمل عليها';
        break;
      case 'RESOLVED':
        bg = AppColors.successLight;
        fg = AppColors.success;
        text = 'تم الحل';
        break;
      case 'CLOSED':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        text = 'مغلقة';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.black54;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
