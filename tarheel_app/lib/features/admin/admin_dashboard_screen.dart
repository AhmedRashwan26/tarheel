import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/upload_service.dart';
import '../../core/network/api_client.dart';
import '../../providers/auth_provider.dart';
import '../auth/role_selection_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;

  bool _isLoadingOverview = false;
  Map<String, dynamic>? _overviewData;

  // Tab 1: Drivers
  bool _isLoadingDrivers = false;
  List<dynamic> _drivers = [];
  String _driverFilterStatus = 'ALL'; // ALL, PENDING, APPROVED, SUSPENDED, REJECTED

  // Tab 2: Financial Performance & User Audit
  bool _isLoadingPerformance = false;
  List<dynamic> _performanceUsers = [];
  String _perfRoleFilter = 'ALL'; // ALL, CLIENT, DRIVER
  final TextEditingController _perfSearchController = TextEditingController();

  // Tab 3: Support Tickets
  bool _isLoadingTickets = false;
  List<dynamic> _tickets = [];
  String _ticketFilterDept = 'ALL';
  String _ticketFilterStatus = 'ALL';

  // Tab 4: Disputes
  bool _isLoadingDisputes = false;
  List<dynamic> _disputes = [];

  // Tab 5: Chat Monitoring
  bool _isLoadingChats = false;
  List<dynamic> _chats = [];

  // Tab 6: Broadcast Form
  String _recipientType = 'ALL';
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _broadcastTitleController = TextEditingController();
  final TextEditingController _broadcastMessageController = TextEditingController();
  bool _sendWhatsApp = true;
  bool _sendEmail = true;
  bool _isSendingBroadcast = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadTabContent(_tabController.index);
    });

    _loadOverview();
    _loadDrivers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userIdController.dispose();
    _perfSearchController.dispose();
    _broadcastTitleController.dispose();
    _broadcastMessageController.dispose();
    super.dispose();
  }

  void _loadTabContent(int index) {
    switch (index) {
      case 0:
        _loadDrivers();
        break;
      case 1:
        _loadPerformance();
        break;
      case 2:
        _loadTickets();
        break;
      case 3:
        _loadDisputes();
        break;
      case 4:
        _loadChats();
        break;
      case 5:
        break;
    }
  }

  // ==================== DATA LOADERS ====================

  Future<void> _loadOverview() async {
    setState(() => _isLoadingOverview = true);
    try {
      final res = await _api.get(ApiEndpoints.adminFinancialOverview);
      if (res.data != null && res.data['data'] != null) {
        setState(() => _overviewData = res.data['data']);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingOverview = false);
  }

  Future<void> _loadDrivers() async {
    setState(() => _isLoadingDrivers = true);
    try {
      final url = _driverFilterStatus == 'PENDING'
          ? ApiEndpoints.adminPendingDrivers
          : (_driverFilterStatus == 'ALL'
              ? ApiEndpoints.adminAllDrivers
              : '${ApiEndpoints.adminAllDrivers}?status=$_driverFilterStatus');
      final res = await _api.get(url);
      if (res.data != null && res.data['data'] != null) {
        setState(() => _drivers = res.data['data'] as List<dynamic>);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء تحميل بيانات السائقين', isError: true);
    }
    if (mounted) setState(() => _isLoadingDrivers = false);
  }

  Future<void> _loadPerformance() async {
    setState(() => _isLoadingPerformance = true);
    try {
      final roleParam = _perfRoleFilter == 'ALL' ? null : _perfRoleFilter;
      final searchParam = _perfSearchController.text.trim().isNotEmpty
          ? _perfSearchController.text.trim()
          : null;
      final url = ApiEndpoints.adminUsersPerformance(role: roleParam, search: searchParam);
      final res = await _api.get(url);
      if (res.data != null && res.data['data'] != null) {
        setState(() => _performanceUsers = res.data['data'] as List<dynamic>);
      }
    } catch (e) {
      _showSnackBar('تعذر تحميل بيانات الأداء المالي للمستخدمين', isError: true);
    }
    if (mounted) setState(() => _isLoadingPerformance = false);
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoadingTickets = true);
    try {
      String query = '';
      if (_ticketFilterDept != 'ALL') query += 'department=$_ticketFilterDept&';
      if (_ticketFilterStatus != 'ALL') query += 'status=$_ticketFilterStatus&';
      final url = '${ApiEndpoints.adminSupportTickets}?$query';
      final res = await _api.get(url);
      if (res.data != null && res.data['data'] != null) {
        setState(() => _tickets = res.data['data'] as List<dynamic>);
      }
    } catch (e) {
      _showSnackBar('تعذر تحميل تذاكر الدعم الفني', isError: true);
    }
    if (mounted) setState(() => _isLoadingTickets = false);
  }

  Future<void> _loadDisputes() async {
    setState(() => _isLoadingDisputes = true);
    try {
      final res = await _api.get(ApiEndpoints.adminDisputes);
      if (res.data != null && res.data['data'] != null) {
        setState(() => _disputes = res.data['data'] as List<dynamic>);
      }
    } catch (e) {
      _showSnackBar('تعذر تحميل النزاعات المالية', isError: true);
    }
    if (mounted) setState(() => _isLoadingDisputes = false);
  }

  Future<void> _loadChats() async {
    setState(() => _isLoadingChats = true);
    try {
      final res = await _api.get(ApiEndpoints.adminChats);
      if (res.data != null && res.data['data'] != null) {
        setState(() => _chats = res.data['data'] as List<dynamic>);
      }
    } catch (e) {
      _showSnackBar('تعذر تحميل محادثات المستخدمين', isError: true);
    }
    if (mounted) setState(() => _isLoadingChats = false);
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _approveDriver(String driverId, String name) async {
    final confirm = await _showConfirmDialog(
      title: 'اعتماد وتفعيل السائق',
      message: 'هل أنت متأكد من مراجعة وثائق الكابتن ($name) وصور السيارة بالكامل والموافقة على تفعيل حسابه؟',
      confirmColor: AppColors.success,
      confirmText: 'اعتماد السائق',
    );
    if (confirm != true) return;

    try {
      await _api.patch(ApiEndpoints.adminApproveDriver(driverId));
      _showSnackBar('تم اعتماد السائق وتفعيله بنجاح، وتم إرسال إشعار ترحيبي له');
      _loadDrivers();
      _loadOverview();
    } catch (e) {
      _showSnackBar('فشل اعتماد السائق', isError: true);
    }
  }

  Future<void> _rejectDriver(String driverId, String name) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض طلب السائق', textDirection: TextDirection.rtl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('يرجى كتابة سبب رفض طلب الكابتن ($name) لتوضيحه له:',
                textDirection: TextDirection.rtl),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'مثال: صورة رخصة السير غير واضحة أو منتهية...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('تأكيد الرفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && reasonController.text.trim().isNotEmpty) {
      try {
        await _api.patch(
          ApiEndpoints.adminRejectDriver(driverId),
          data: {'reason': reasonController.text.trim()},
        );
        _showSnackBar('تم رفض طلب السائق وتوثيق السبب وإشعاره به');
        _loadDrivers();
        _loadOverview();
      } catch (e) {
        _showSnackBar('فشل رفض السائق', isError: true);
      }
    }
  }

  Future<void> _suspendDriver(String driverId, String name) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعليق حساب السائق مؤقتاً', textDirection: TextDirection.rtl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('يرجى إدخال سبب تعليق حساب الكابتن ($name) ومخالفته للسياسات:',
                textDirection: TextDirection.rtl),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'مثال: مخالفة سياسة عدم التعامل النقدي أو شكوى متكررة...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('تعليق الحساب', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && reasonController.text.trim().isNotEmpty) {
      try {
        await _api.patch(
          ApiEndpoints.adminSuspendDriver(driverId),
          data: {'reason': reasonController.text.trim()},
        );
        _showSnackBar('تم تعليق حساب السائق وإرسال تحذير له عبر الواتساب والتطبيق');
        _loadDrivers();
        _loadOverview();
      } catch (e) {
        _showSnackBar('فشل تعليق الحساب', isError: true);
      }
    }
  }

  Future<void> _unsuspendDriver(String driverId, String name) async {
    final confirm = await _showConfirmDialog(
      title: 'فك تعليق الحساب',
      message: 'هل ترغب في فك تعليق حساب الكابتن ($name) وإعادة تفعيله لمزاولة استقبال العروض والرحلات؟',
      confirmColor: AppColors.primary,
      confirmText: 'فك التعليق وإعادة التفعيل',
    );
    if (confirm != true) return;

    try {
      await _api.patch(ApiEndpoints.adminUnsuspendDriver(driverId));
      _showSnackBar('تم فك تعليق حساب السائق وإعادة تفعيله بنجاح');
      _loadDrivers();
      _loadOverview();
    } catch (e) {
      _showSnackBar('فشل فك تعليق الحساب', isError: true);
    }
  }

  Future<void> _resolveDispute(String contractId, String action, String title) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, textDirection: TextDirection.rtl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('أدخل حيثيات وتفاصيل قرار الإدارة الصادر للطرفين:',
                textDirection: TextDirection.rtl),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'شرح مسبب القرار الإداري...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'RELEASE_TO_DRIVER' ? AppColors.success : AppColors.primary,
            ),
            onPressed: () {
              if (noteController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('إصدار القرار الإداري', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && noteController.text.trim().isNotEmpty) {
      try {
        await _api.post(
          ApiEndpoints.adminResolveDispute(contractId),
          data: {
            'action': action,
            'resolutionNote': noteController.text.trim(),
          },
        );
        _showSnackBar('تم تنفيذ القرار الإداري وتسوية مبالغ الضمان وإشعار الطرفين');
        _loadDisputes();
        _loadOverview();
      } catch (e) {
        _showSnackBar('فشل تسوية النزاع', isError: true);
      }
    }
  }

  Future<void> _replyToTicket(String ticketId) async {
    final replyController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الرد كمسؤول خدمة العملاء', textDirection: TextDirection.rtl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اكتب الرد الرسمي الذي سيصل للمستخدم مباشرة:',
                textDirection: TextDirection.rtl),
            const SizedBox(height: 12),
            TextField(
              controller: replyController,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'مرحباً بك، يسعدنا في منصة ترحيل خدمتك...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (replyController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('إرسال الرد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && replyController.text.trim().isNotEmpty) {
      try {
        await _api.post(
          ApiEndpoints.replyTicket(ticketId),
          data: {'message': replyController.text.trim()},
        );
        _showSnackBar('تم إرسال الرد للمستخدم بنجاح');
        _loadTickets();
      } catch (e) {
        _showSnackBar('تعذر إرسال الرد', isError: true);
      }
    }
  }

  Future<void> _updateTicketStatus(String ticketId, String status) async {
    try {
      await _api.patch(
        ApiEndpoints.adminUpdateTicketStatus(ticketId),
        data: {'status': status},
      );
      _showSnackBar('تم تحديث حالة التذكرة بنجاح');
      _loadTickets();
      _loadOverview();
    } catch (e) {
      _showSnackBar('تعذر تحديث حالة التذكرة', isError: true);
    }
  }

  Future<void> _sendBroadcastNotification() async {
    final title = _broadcastTitleController.text.trim();
    final message = _broadcastMessageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      _showSnackBar('يرجى كتابة عنوان الإشعار ومحتوى الرسالة', isError: true);
      return;
    }

    if (_recipientType == 'USER' && _userIdController.text.trim().isEmpty) {
      _showSnackBar('يرجى تحديد معرف المستخدم المستهدف', isError: true);
      return;
    }

    setState(() => _isSendingBroadcast = true);
    try {
      final res = await _api.post(
        ApiEndpoints.adminBroadcastNotification,
        data: {
          'recipientType': _recipientType,
          if (_recipientType == 'USER') 'userId': _userIdController.text.trim(),
          'title': title,
          'message': message,
          'sendWhatsApp': _sendWhatsApp,
          'sendEmail': _sendEmail,
        },
      );

      final count = res.data?['data']?['recipientCount'] ?? 0;
      _showSnackBar('تم بث التنبيه بنجاح إلى ($count) مستخدم عبر القنوات المختارة');
      _broadcastTitleController.clear();
      _broadcastMessageController.clear();
    } catch (e) {
      _showSnackBar('فشل إرسال التنبيه', isError: true);
    }
    if (mounted) setState(() => _isSendingBroadcast = false);
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required Color confirmColor,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, textDirection: TextDirection.rtl),
        content: Text(message, textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== INSPECT DRIVER KYC DIALOG ====================

  void _inspectDriverDocuments(Map<String, dynamic> driver) {
    final user = driver['user'] ?? {};
    final vehicle = driver['vehicle'] ?? {};

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 800,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ملف الكابتن: ${user['fullName'] ?? 'غير معروف'}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textDirection: TextDirection.rtl,
                      ),
                      Text(
                        'رقم الجوال: ${user['phoneNumber'] ?? '-'} | الهوية: ${driver['nationalId'] ?? '-'}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),

              // Scrollable Details
              Expanded(
                child: ListView(
                  children: [
                    // Bank info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🏦 بيانات الحساب البنكي المعتمد للتحويل:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 6),
                          Text('اسم البنك: ${driver['bankName'] ?? 'غير مسجل'}', textDirection: TextDirection.rtl),
                          Text('اسم صاحب الحساب: ${driver['bankAccountHolderName'] ?? 'غير مسجل'}', textDirection: TextDirection.rtl),
                          Text('رقم الآيبان (IBAN): ${driver['iban'] ?? 'غير مسجل'}', textDirection: TextDirection.ltr),
                          if (driver['bankCertificatePdfUrl'] != null) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _openImagePreview(driver['bankCertificatePdfUrl'], 'شهادة الحساب البنكي'),
                              icon: const Icon(Icons.picture_as_pdf, size: 16),
                              label: const Text('عرض مستند شهادة الآيبان البنكي'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Official Documents Images
                    const Text(
                      '📄 الوثائق الرسمية والمستندات الثبوتية:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildDocImageTile('الهوية الوطنية', driver['idCardPhotoUrl']),
                        _buildDocImageTile('رخصة القيادة', driver['driverLicenseUrl']),
                        _buildDocImageTile('رخصة سير المركبة (الاستمارة)', driver['vehicleRegistrationUrl']),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Vehicle Details & 5 Photos
                    Text(
                      '🚗 صور وتفاصيل المركبة (${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''} - ${vehicle['year'] ?? ''}) - لوحة: ${vehicle['plateNumber'] ?? ''}:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildDocImageTile('الواجهة الأمامية', vehicle['photoFrontUrl']),
                        _buildDocImageTile('الواجهة الخلفية', vehicle['photoBackUrl']),
                        _buildDocImageTile('الجانب الأيمن', vehicle['photoRightUrl']),
                        _buildDocImageTile('الجانب الأيسر', vehicle['photoLeftUrl']),
                        _buildDocImageTile('المقاعد الداخلية والمكيف', vehicle['photoInteriorUrl']),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _rejectDriver(driver['id'], user['fullName'] ?? '');
                    },
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text('رفض الطلب', style: TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(width: 12),
                  if (driver['verificationStatus'] == 'SUSPENDED')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _unsuspendDriver(driver['id'], user['fullName'] ?? '');
                      },
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text('فك تعليق الحساب', style: TextStyle(color: Colors.white)),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _suspendDriver(driver['id'], user['fullName'] ?? '');
                      },
                      icon: const Icon(Icons.pause_circle_outline, color: Colors.orange),
                      label: const Text('تعليق مؤقت', style: TextStyle(color: Colors.orange)),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _approveDriver(driver['id'], user['fullName'] ?? '');
                    },
                    icon: const Icon(Icons.verified, color: Colors.white),
                    label: const Text('اعتماد وتفعيل السائق', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocImageTile(String label, String? url) {
    final formattedUrl = UploadService.formatUrl(url);
    return Container(
      width: 170,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: formattedUrl.isNotEmpty
                ? Image.network(
                    formattedUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 110,
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  )
                : Container(
                    height: 110,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Text('غير مرفق', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (formattedUrl.isNotEmpty)
            TextButton(
              onPressed: () => _openImagePreview(formattedUrl, label),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              child: const Text('تكبير الصورة', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  void _openImagePreview(String url, String title) {
    final formattedUrl = UploadService.formatUrl(url);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InteractiveViewer(
                child: Image.network(
                  formattedUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('تعذر تحميل الصورة'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'لوحة التحكم الإدارية',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'منصة تـرحـيـل (Tarheel Admin)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              _loadOverview();
              _loadTabContent(_tabController.index);
            },
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.accent,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.badge_rounded), text: 'السائقين والوثائق (KYC)'),
            Tab(icon: Icon(Icons.analytics_rounded), text: 'الأداء المالي وسجل النشاط'),
            Tab(icon: Icon(Icons.support_agent_rounded), text: 'خدمة العملاء والتذاكر'),
            Tab(icon: Icon(Icons.gavel_rounded), text: 'البت في النزاعات المالية'),
            Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: 'مراقبة المحادثات'),
            Tab(icon: Icon(Icons.campaign_rounded), text: 'مركز التنبيهات الجماعية'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Financial & Platform KPIs Bar
          _buildTopKpiBar(),

          // Main Tabs View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDriversTab(),
                _buildPerformanceTab(),
                _buildTicketsTab(),
                _buildDisputesTab(),
                _buildChatsTab(),
                _buildBroadcastTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TOP KPI BAR ====================

  Widget _buildTopKpiBar() {
    final fin = _overviewData?['financials'] ?? {};
    final stats = _overviewData?['stats'] ?? {};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: _isLoadingOverview
          ? const Center(
              child: SizedBox(
                height: 38,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildKpiChip(
                    title: 'حجم التداول الكلي',
                    value: '${(fin['totalVolumePaidByClientsSAR'] ?? 0).toStringAsFixed(1)} ر.س',
                    icon: Icons.payments_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiChip(
                    title: 'أرباح المنصة (13.50%)',
                    value: '${(fin['totalPlatformCommissionEarnedSAR'] ?? 0).toStringAsFixed(1)} ر.س',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiChip(
                    title: 'الضمان المحتجز حالياً',
                    value: '${(fin['totalEscrowCurrentlyHeldSAR'] ?? 0).toStringAsFixed(1)} ر.س',
                    icon: Icons.security_rounded,
                    color: AppColors.escrow,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiChip(
                    title: 'سائقين قيد المراجعة',
                    value: '${stats['pendingDrivers'] ?? 0}',
                    icon: Icons.pending_actions_rounded,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiChip(
                    title: 'نزاعات مالية مفتوحة',
                    value: '${stats['disputedContractsCount'] ?? 0}',
                    icon: Icons.gavel_rounded,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  _buildKpiChip(
                    title: 'تذاكر دعم مفتوحة',
                    value: '${stats['openTicketsCount'] ?? 0}',
                    icon: Icons.mark_email_unread_rounded,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiChip({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TAB 1: DRIVERS & KYC ====================

  Widget _buildDriversTab() {
    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDriverFilterChip('الكل', 'ALL'),
                const SizedBox(width: 8),
                _buildDriverFilterChip('قيد المراجعة ⏳', 'PENDING'),
                const SizedBox(width: 8),
                _buildDriverFilterChip('معتمد ومفعل ✅', 'APPROVED'),
                const SizedBox(width: 8),
                _buildDriverFilterChip('معلق مؤقتاً ⚠️', 'SUSPENDED'),
                const SizedBox(width: 8),
                _buildDriverFilterChip('مرفوض ❌', 'REJECTED'),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: _isLoadingDrivers
              ? const Center(child: CircularProgressIndicator())
              : _drivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('لا توجد طلبات سائقين مطابقة لهذا الفلتر حالياً'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _drivers.length,
                      itemBuilder: (ctx, idx) {
                        final driver = _drivers[idx];
                        return _buildDriverCard(driver);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDriverFilterChip(String label, String status) {
    final selected = _driverFilterStatus == status;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary)),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      onSelected: (_) {
        setState(() => _driverFilterStatus = status);
        _loadDrivers();
      },
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final user = driver['user'] ?? {};
    final vehicle = driver['vehicle'] ?? {};
    final status = driver['verificationStatus'] ?? 'PENDING';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'APPROVED':
        statusColor = AppColors.success;
        statusText = 'معتمد ونشط';
        break;
      case 'SUSPENDED':
        statusColor = Colors.orange.shade800;
        statusText = 'معلق مؤقتاً';
        break;
      case 'REJECTED':
        statusColor = AppColors.error;
        statusText = 'مرفوض';
        break;
      default:
        statusColor = Colors.blue;
        statusText = 'قيد المراجعة';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  user['fullName'] ?? 'سائق غير معروف',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الجوال: ${user['phoneNumber'] ?? '-'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textDirection: TextDirection.ltr,
                ),
                Text(
                  'المركبة: ${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''} (${vehicle['year'] ?? ''}) - لوحة: ${vehicle['plateNumber'] ?? ''}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            if (driver['rejectionReason'] != null) ...[
              const SizedBox(height: 6),
              Text(
                'سبب التعليق/الرفض: ${driver['rejectionReason']}',
                style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _inspectDriverDocuments(driver),
                  icon: const Icon(Icons.document_scanner_rounded, size: 18),
                  label: const Text('معاينة الوثائق وصور السيارة الـ 5'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                ),
                Row(
                  children: [
                    if (status != 'APPROVED')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => _approveDriver(driver['id'], user['fullName'] ?? ''),
                        child: const Text('اعتماد', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    const SizedBox(width: 8),
                    if (status != 'SUSPENDED' && status != 'REJECTED')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => _suspendDriver(driver['id'], user['fullName'] ?? ''),
                        child: const Text('تعليق', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    if (status == 'SUSPENDED')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => _unsuspendDriver(driver['id'], user['fullName'] ?? ''),
                        child: const Text('فك التعليق', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 2: FINANCIAL PERFORMANCE & USER AUDIT ====================

  Widget _buildPerformanceTab() {
    return Column(
      children: [
        // Search & Role Filter Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _perfSearchController,
                  textDirection: TextDirection.rtl,
                  onSubmitted: (_) => _loadPerformance(),
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم، الجوال، أو البريد الإلكتروني...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _perfSearchController.clear();
                        _loadPerformance();
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadPerformance,
                icon: const Icon(Icons.filter_list_rounded, size: 18, color: Colors.white),
                label: const Text('بحث وتصفية', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),

        // Role Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildPerfRoleChip('كافة المستخدمين (الكل)', 'ALL'),
              const SizedBox(width: 8),
              _buildPerfRoleChip('السائقين والكباتن 🚗', 'DRIVER'),
              const SizedBox(width: 8),
              _buildPerfRoleChip('العملاء والركاب 👤', 'CLIENT'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Users List
        Expanded(
          child: _isLoadingPerformance
              ? const Center(child: CircularProgressIndicator())
              : _performanceUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('لا يوجد مستخدمين يطابقون معايير البحث الحالية'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: _performanceUsers.length,
                      itemBuilder: (ctx, idx) {
                        final u = _performanceUsers[idx];
                        return _buildUserPerformanceCard(u);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPerfRoleChip(String label, String role) {
    final selected = _perfRoleFilter == role;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontSize: 12)),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      onSelected: (_) {
        setState(() => _perfRoleFilter = role);
        _loadPerformance();
      },
    );
  }

  Widget _buildUserPerformanceCard(Map<String, dynamic> u) {
    final isDriver = u['role'] == 'DRIVER';
    final vehicle = u['vehicle'] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDriver ? AppColors.accent.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isDriver ? 'سائق / كابتن 🚗' : 'عميل / راكب 👤',
                    style: TextStyle(
                      color: isDriver ? AppColors.accentDark : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  u['fullName'] ?? 'مستخدم',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الجوال: ${u['phoneNumber'] ?? '-'} | ${u['email'] ?? ''}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  textDirection: TextDirection.ltr,
                ),
                if (isDriver && vehicle['plateNumber'] != null)
                  Text(
                    'مركبة: ${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''} (${vehicle['plateNumber'] ?? ''})',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    textDirection: TextDirection.rtl,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Performance Metrics Strip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: isDriver
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniPerfStat('الرصيد المتاح', '${u['walletBalance'] ?? 0} ر.س', AppColors.success),
                        _buildMiniPerfStat('الضمان المعلق', '${u['pendingEscrowBalance'] ?? 0} ر.س', AppColors.escrow),
                        _buildMiniPerfStat('الرحلات المنفذة', '${u['totalTripsCount'] ?? 0}', AppColors.primary),
                        _buildMiniPerfStat('التقييم العام', '★ ${(u['ratingAverage'] ?? 5.0).toStringAsFixed(1)}', Colors.orange.shade800),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniPerfStat('إجمالي المنفق', '${(u['totalSpentSAR'] ?? 0).toStringAsFixed(1)} ر.س', AppColors.primary),
                        _buildMiniPerfStat('الضمان النشط', '${(u['activeEscrowHeldSAR'] ?? 0).toStringAsFixed(1)} ر.س', AppColors.escrow),
                        _buildMiniPerfStat('الرحلات المكتملة', '${u['completedTripsCount'] ?? 0}', AppColors.success),
                        _buildMiniPerfStat('إجمالي العقود', '${u['totalContractsCount'] ?? 0}', AppColors.secondary),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            // Action Button to view Full Activity History
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => _openUserActivityHistoryDialog(
                    u['userId'],
                    u['fullName'] ?? '',
                    u['role'] ?? 'CLIENT',
                  ),
                  icon: const Icon(Icons.history_edu_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'عرض سجل النشاط الكامل والعمليات المالية',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPerfStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  void _openUserActivityHistoryDialog(String userId, String userName, String role) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic>? fullUser;
    try {
      final res = await _api.get(ApiEndpoints.adminUserActivityHistory(userId));
      if (res.data != null && res.data['data'] != null) {
        fullUser = res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context); // Close loader

    if (fullUser == null) {
      _showSnackBar('تعذر جلب تفاصيل سجل النشاط للمستخدم', isError: true);
      return;
    }

    final isDriver = role == 'DRIVER';
    final driverProfile = fullUser['driverProfile'] ?? {};
    final contracts = isDriver
        ? (driverProfile['contracts'] as List<dynamic>? ?? [])
        : (fullUser['contractsAsClient'] as List<dynamic>? ?? []);
    final walletTx = fullUser['walletTransactions'] as List<dynamic>? ?? [];
    final reviews = isDriver
        ? (driverProfile['reviewsReceived'] as List<dynamic>? ?? [])
        : (fullUser['reviewsGiven'] as List<dynamic>? ?? []);
    final tickets = fullUser['supportTickets'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (ctx) => DefaultTabController(
        length: 4,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Container(
            width: 850,
            constraints: const BoxConstraints(maxHeight: 720),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'سجل النشاط والعمليات: $userName (${isDriver ? 'سائق معتمد' : 'عميل'})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          'الجوال: ${fullUser?['phoneNumber'] ?? '-'} | البريد: ${fullUser?['email'] ?? '-'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 18),

                // Sub-tabs in history dialog
                TabBar(
                  isScrollable: true,
                  indicatorColor: AppColors.accent,
                  labelColor: AppColors.primary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(icon: const Icon(Icons.receipt_long_rounded, size: 18), text: 'العقود والرحلات (${contracts.length})'),
                    Tab(icon: const Icon(Icons.account_balance_wallet_rounded, size: 18), text: 'سجل المحفظة والمالية (${walletTx.length})'),
                    Tab(icon: const Icon(Icons.star_rate_rounded, size: 18), text: 'التقييمات (${reviews.length})'),
                    Tab(icon: const Icon(Icons.support_agent_rounded, size: 18), text: 'تذاكر الدعم (${tickets.length})'),
                  ],
                ),
                const SizedBox(height: 12),

                // Sub-tabs view
                Expanded(
                  child: TabBarView(
                    children: [
                      // Sub-tab 1: Contracts
                      contracts.isEmpty
                          ? const Center(child: Text('لا توجد عقود مسجلة لهذا المستخدم'))
                          : ListView.builder(
                              itemCount: contracts.length,
                              itemBuilder: (_, i) {
                                final c = contracts[i];
                                final trip = c['tripRequest'] ?? {};
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      'المسار: من (${trip['pickupAddress'] ?? ''}) إلى (${trip['dropoffAddress'] ?? ''})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    subtitle: Text(
                                      'الإجمالي: ${c['totalPaidByClient']} ر.س | عمولة 13.50%: ${c['platformCommissionAmount']} ر.س | صافي السائق: ${c['driverEarnings']} ر.س | حالة الضمان: ${c['escrowStatus']}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: c['contractStatus'] == 'COMPLETED' ? AppColors.successLight : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        c['contractStatus'] ?? '',
                                        style: TextStyle(
                                          color: c['contractStatus'] == 'COMPLETED' ? AppColors.success : Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Sub-tab 2: Wallet Transactions
                      walletTx.isEmpty
                          ? const Center(child: Text('لا توجد عمليات مالية مسجلة في المحفظة'))
                          : ListView.builder(
                              itemCount: walletTx.length,
                              itemBuilder: (_, i) {
                                final tx = walletTx[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
                                      child: const Icon(Icons.monetization_on, color: AppColors.primary, size: 20),
                                    ),
                                    title: Text(
                                      '${tx['transactionType']}: ${tx['amount']} ر.س',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      'المرجع: ${tx['reference'] ?? '-'} | التاريخ: ${tx['createdAt']?.toString().substring(0, 10) ?? ''}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Sub-tab 3: Reviews
                      reviews.isEmpty
                          ? const Center(child: Text('لا توجد تقييمات مسجلة'))
                          : ListView.builder(
                              itemCount: reviews.length,
                              itemBuilder: (_, i) {
                                final rev = reviews[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 18),
                                        const SizedBox(width: 4),
                                        Text('${rev['rating']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    title: Text(rev['comment'] ?? 'بدون تعليق', textDirection: TextDirection.rtl),
                                  ),
                                );
                              },
                            ),

                      // Sub-tab 4: Support Tickets
                      tickets.isEmpty
                          ? const Center(child: Text('لا توجد تذاكر دعم مسجلة لهذا المستخدم'))
                          : ListView.builder(
                              itemCount: tickets.length,
                              itemBuilder: (_, i) {
                                final t = tickets[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(t['subject'] ?? '', textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    subtitle: Text(t['description'] ?? '', textDirection: TextDirection.rtl, maxLines: 2),
                                    trailing: Text(t['status'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== TAB 3: SUPPORT TICKETS ====================

  Widget _buildTicketsTab() {
    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTicketDeptFilterChip('كافة الأقسام', 'ALL'),
                const SizedBox(width: 8),
                _buildTicketDeptFilterChip('خدمة العملاء', 'CUSTOMER_SERVICE'),
                const SizedBox(width: 8),
                _buildTicketDeptFilterChip('الدعم الفني', 'TECHNICAL_SUPPORT'),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: _isLoadingTickets
              ? const Center(child: CircularProgressIndicator())
              : _tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('لا توجد تذاكر دعم فني أو خدمة عملاء حالياً'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _tickets.length,
                      itemBuilder: (ctx, idx) {
                        final ticket = _tickets[idx];
                        return _buildTicketCard(ticket);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTicketDeptFilterChip(String label, String dept) {
    final selected = _ticketFilterDept == dept;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary)),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      onSelected: (_) {
        setState(() => _ticketFilterDept = dept);
        _loadTickets();
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final user = ticket['user'] ?? {};
    final replies = ticket['replies'] as List<dynamic>? ?? [];
    final status = ticket['status'] ?? 'OPEN';
    final dept = ticket['department'] == 'CUSTOMER_SERVICE' ? 'خدمة العملاء' : 'الدعم الفني';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: status == 'RESOLVED'
                    ? AppColors.success.withValues(alpha: 0.12)
                    : Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: status == 'RESOLVED' ? AppColors.success : Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                ticket['subject'] ?? 'بدون عنوان',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textDirection: TextDirection.rtl,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'من: ${user['fullName'] ?? 'مستخدم'} (${user['role'] ?? ''}) - قسم: $dept',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textDirection: TextDirection.rtl,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ticket['description'] ?? '',
                    style: const TextStyle(fontSize: 14),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 12),

                // Replies Thread
                if (replies.isNotEmpty) ...[
                  const Text('الردود السابقة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...replies.map((r) {
                    final isSupport = r['senderRole'] == 'ADMIN' || r['senderRole'] == 'SUPPORT_AGENT';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSupport ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r['sender']?['fullName'] ?? 'المستخدم'} (${isSupport ? 'فريق الدعم' : 'العميل'}):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSupport ? AppColors.primary : AppColors.textPrimary,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 4),
                          Text(r['message'] ?? '', textDirection: TextDirection.rtl),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _replyToTicket(ticket['id']),
                      icon: const Icon(Icons.reply_rounded, size: 18, color: Colors.white),
                      label: const Text('إرسال رد رسمي', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                    Row(
                      children: [
                        if (status != 'RESOLVED')
                          TextButton(
                            onPressed: () => _updateTicketStatus(ticket['id'], 'RESOLVED'),
                            child: const Text('تحديد كـ "تم الحل"', style: TextStyle(color: AppColors.success)),
                          ),
                        if (status != 'CLOSED')
                          TextButton(
                            onPressed: () => _updateTicketStatus(ticket['id'], 'CLOSED'),
                            child: const Text('إغلاق التذكرة', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: DISPUTES ====================

  Widget _buildDisputesTab() {
    return _isLoadingDisputes
        ? const Center(child: CircularProgressIndicator())
        : _disputes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_rounded, size: 54, color: AppColors.success),
                    const SizedBox(height: 12),
                    const Text('لا توجد نزاعات مالية معلقة، جميع المعاملات تسير بانضباط تام'),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _disputes.length,
                itemBuilder: (ctx, idx) {
                  final contract = _disputes[idx];
                  return _buildDisputeCard(contract);
                },
              );
  }

  Widget _buildDisputeCard(Map<String, dynamic> contract) {
    final client = contract['client'] ?? {};
    final driver = contract['driverProfile']?['user'] ?? {};
    final trip = contract['tripRequest'] ?? {};
    final escrowStatus = contract['escrowStatus'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: escrowStatus == 'DISPUTED' ? AppColors.error.withValues(alpha: 0.12) : AppColors.escrow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    escrowStatus == 'DISPUTED' ? 'نزاع مالي مفتوح ⚠️' : 'ضمان محتجز بالمنصة 🛡️',
                    style: TextStyle(
                      color: escrowStatus == 'DISPUTED' ? AppColors.error : AppColors.escrow,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  'المبلغ الكلي: ${contract['totalPaidByClient']} ر.س',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'مسار الرحلة: من (${trip['pickupAddress'] ?? ''}) إلى (${trip['dropoffAddress'] ?? ''})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 6),
            Text('العميل: ${client['fullName']} (جوال: ${client['phoneNumber'] ?? '-'})', textDirection: TextDirection.rtl),
            Text('السائق: ${driver['fullName']} (جوال: ${driver['phoneNumber'] ?? '-'})', textDirection: TextDirection.rtl),
            const SizedBox(height: 8),

            // Financial Split
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('صافي السائق (86.50%): ${contract['driverEarnings']} ر.س', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('عمولة المنصة (13.50%): ${contract['platformCommissionAmount']} ر.س', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                  Text('الضريبة (15%): ${contract['vatAmount']} ر.س', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dispute Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _resolveDispute(
                    contract['id'],
                    'REFUND_TO_CLIENT',
                    'البت لصالح العميل واسترجاع المبلغ',
                  ),
                  icon: const Icon(Icons.replay_rounded, color: AppColors.primary),
                  label: const Text('استرجاع المبلغ للعميل', style: TextStyle(color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _resolveDispute(
                    contract['id'],
                    'RELEASE_TO_DRIVER',
                    'البت لصالح السائق وتحويل المستحقات',
                  ),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: const Text('تحويل المستحقات للسائق', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 4: CHAT AUDIT ====================

  Widget _buildChatsTab() {
    return _isLoadingChats
        ? const Center(child: CircularProgressIndicator())
        : _chats.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum_rounded, size: 54, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('لا توجد محادثات نشطة حالياً لمراقبتها'),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _chats.length,
                itemBuilder: (ctx, idx) {
                  final chat = _chats[idx];
                  return _buildChatAuditCard(chat);
                },
              );
  }

  Widget _buildChatAuditCard(Map<String, dynamic> chat) {
    final client = chat['client'] ?? {};
    final driver = chat['driverProfile']?['user'] ?? {};
    final lastMsg = (chat['chatMessages'] as List<dynamic>?)?.isNotEmpty == true
        ? chat['chatMessages'][0]
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.chat, color: AppColors.primary),
        ),
        title: Text(
          'محادثة: ${client['fullName'] ?? 'عميل'} ↔ ${driver['fullName'] ?? 'سائق'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              lastMsg != null ? 'آخر رسالة: ${lastMsg['content'] ?? 'ملاحظة صوتية أو موقع'}' : 'لا توجد رسائل',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onPressed: () => _openChatMessagesViewer(chat['id'], client['fullName'] ?? '', driver['fullName'] ?? ''),
          child: const Text('تدقيق المحادثة', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
    );
  }

  void _openChatMessagesViewer(String contractId, String clientName, String driverName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    List<dynamic> messages = [];
    try {
      final res = await _api.get(ApiEndpoints.adminChatMessages(contractId));
      if (res.data != null && res.data['data'] != null) {
        messages = res.data['data'] as List<dynamic>;
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context); // close loader

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 650),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  Text(
                    'سجل المحادثة: $clientName ↔ $driverName',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
              const Divider(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مراقبة الالتزام: يمنع تداول أرقام الحسابات البنكية المباشرة أو الاتفاق على دفع نقدي خارج المنصة.',
                        style: TextStyle(fontSize: 11, color: Colors.brown),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('لا توجد رسائل مسجلة'))
                    : ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final msg = messages[i];
                          final sender = msg['sender'] ?? {};
                          final isClient = sender['role'] == 'CLIENT';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            alignment: isClient ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isClient ? AppColors.primaryLight.withValues(alpha: 0.15) : AppColors.accentLight.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${sender['fullName']} (${isClient ? 'عميل' : 'سائق'})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: isClient ? AppColors.primary : AppColors.accentDark,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 4),
                                  if (msg['messageType'] == 'VOICE_NOTE')
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.mic, size: 16, color: AppColors.accent),
                                        SizedBox(width: 4),
                                        Text('تسجيل صوتي موثق عبر التطبيق', style: TextStyle(fontSize: 13)),
                                      ],
                                    )
                                  else if (msg['messageType'] == 'LOCATION')
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: AppColors.primary),
                                        SizedBox(width: 4),
                                        Text('مشاركة موقع جغرافي مباشر', style: TextStyle(fontSize: 13)),
                                      ],
                                    )
                                  else
                                    Text(msg['content'] ?? '', textDirection: TextDirection.rtl),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TAB 5: BROADCAST NOTIFICATIONS ====================

  Widget _buildBroadcastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.campaign_rounded, size: 28, color: AppColors.accent),
                  SizedBox(width: 10),
                  Text(
                    'مركز إرسال التنبيهات المخصصة والجماعية',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'يمكنك إرسال تنبيهات رسمية وتوجيهات لكافة المستخدمين أو شريحة محددة عبر قنوات متعددة.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textDirection: TextDirection.rtl,
              ),
              const Divider(height: 28),

              // Recipient Selector
              const Text('الجمهور المستهدف:', style: TextStyle(fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  _buildRecipientRadio('كافة المستخدمين', 'ALL'),
                  _buildRecipientRadio('العملاء فقط', 'CLIENTS'),
                  _buildRecipientRadio('السائقين فقط', 'DRIVERS'),
                  _buildRecipientRadio('مستخدم محدد', 'USER'),
                ],
              ),
              if (_recipientType == 'USER') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _userIdController,
                  decoration: InputDecoration(
                    labelText: 'معرف المستخدم (User UUID)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Title
              TextField(
                controller: _broadcastTitleController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'عنوان الإشعار',
                  hintText: 'مثال: تنبيه هام بشأن جدول المشاوير في رمضان...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              // Message Body
              TextField(
                controller: _broadcastMessageController,
                maxLines: 5,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'محتوى الرسالة',
                  hintText: 'اكتب نص التنبيه أو التوجيه بالتفصيل...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              // Multi-Channel Checkboxes
              const Text('قنوات الإرسال:', style: TextStyle(fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Checkbox(
                    value: true,
                    onChanged: null, // Always In-App
                  ),
                  const Text('تنبيه داخل التطبيق (In-App)'),
                  const SizedBox(width: 20),
                  Checkbox(
                    value: _sendWhatsApp,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _sendWhatsApp = v ?? true),
                  ),
                  const Text('رسالة واتساب رسمية (WhatsApp)'),
                  const SizedBox(width: 20),
                  Checkbox(
                    value: _sendEmail,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _sendEmail = v ?? true),
                  ),
                  const Text('بريد إلكتروني (Email)'),
                ],
              ),
              const SizedBox(height: 24),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSendingBroadcast ? null : _sendBroadcastNotification,
                  icon: _isSendingBroadcast
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: Text(
                    _isSendingBroadcast ? 'جاري بث التنبيه...' : 'إرسال التنبيه الآن',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientRadio(String label, String value) {
    final selected = _recipientType == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary)),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      onSelected: (_) => setState(() => _recipientType = value),
    );
  }
}
