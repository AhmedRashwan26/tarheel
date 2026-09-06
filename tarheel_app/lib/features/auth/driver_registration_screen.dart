import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/upload_service.dart';
import '../../providers/auth_provider.dart';
import '../terms/terms_and_conditions_screen.dart';
import '../driver/driver_main_screen.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Info
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();

  // Document Uploads
  String? _personalPhotoUrl;
  String? _personalPhotoFileName;
  bool _isUploadingPersonal = false;

  String? _idCardPhotoUrl;
  String? _idCardFileName;
  bool _isUploadingIdCard = false;

  String? _licenseUrl;
  String? _licenseFileName;
  bool _isUploadingLicense = false;

  String? _vehicleRegUrl;
  String? _vehicleRegFileName;
  bool _isUploadingVehicleReg = false;

  // Vehicle Info
  final _brandController = TextEditingController(text: 'تويوتا');
  final _modelController = TextEditingController(text: 'كامري');
  final _yearController = TextEditingController(text: '2024');
  final _plateController = TextEditingController(text: 'أ ب ج 1234');
  int _capacity = 4;
  bool _isAirConditioned = true;

  // 5 Vehicle Photos
  String? _photoFrontUrl;
  String? _photoFrontFileName;
  bool _isUploadingFront = false;

  String? _photoBackUrl;
  String? _photoBackFileName;
  bool _isUploadingBack = false;

  String? _photoRightUrl;
  String? _photoRightFileName;
  bool _isUploadingRight = false;

  String? _photoLeftUrl;
  String? _photoLeftFileName;
  bool _isUploadingLeft = false;

  String? _photoInteriorUrl;
  String? _photoInteriorFileName;
  bool _isUploadingInterior = false;

  // Bank Info
  final _bankNameController = TextEditingController(text: 'مصرف الراجحي');
  final _ibanController = TextEditingController(text: 'SA0380000000608010167519');
  final _accountHolderController = TextEditingController();
  String? _bankCertificatePdfUrl;
  String? _selectedPdfFileName;
  bool _isUploadingBankPdf = false;

  // Terms & Conditions
  bool _agreeToCommission = true;
  bool _agreeToAntiCash = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        if (auth.user?['fullName'] != null && !auth.user!['fullName'].toString().startsWith('كابتن ')) {
          _fullNameController.text = auth.user!['fullName'];
        }
        if (auth.user?['phoneNumber'] != null) {
          _phoneController.text = auth.user!['phoneNumber'];
        }
        if (auth.user?['driverProfile'] != null) {
          final dp = auth.user!['driverProfile'];
          if (dp['nationalId'] != null) _nationalIdController.text = dp['nationalId'];
          if (dp['bankName'] != null) _bankNameController.text = dp['bankName'];
          if (dp['iban'] != null) _ibanController.text = dp['iban'];
          if (dp['bankAccountHolderName'] != null) _accountHolderController.text = dp['bankAccountHolderName'];
          if (dp['vehicle'] != null) {
            final v = dp['vehicle'];
            if (v['brand'] != null) _brandController.text = v['brand'];
            if (v['model'] != null) _modelController.text = v['model'];
            if (v['year'] != null) _yearController.text = v['year'].toString();
            if (v['plateNumber'] != null) _plateController.text = v['plateNumber'];
            if (v['capacity'] != null) _capacity = v['capacity'];
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _bankNameController.dispose();
    _ibanController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _pickPersonalPhotoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'webp'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() => _isUploadingPersonal = true);
        final uploadRes = await UploadService().uploadFile(file);
        setState(() => _isUploadingPersonal = false);

        if (uploadRes.success && uploadRes.url != null) {
          setState(() {
            _personalPhotoFileName = file.name;
            _personalPhotoUrl = uploadRes.url;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ تم رفع الصورة الشخصية بنجاح: ${file.name}'), backgroundColor: AppColors.success),
            );
          }
        }
      }
    } catch (_) {
      setState(() => _isUploadingPersonal = false);
    }
  }

  Future<void> _pickDocumentFile(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          if (docType == 'idCard') _isUploadingIdCard = true;
          if (docType == 'license') _isUploadingLicense = true;
          if (docType == 'vehicleReg') _isUploadingVehicleReg = true;
        });

        final uploadRes = await UploadService().uploadFile(file);
        setState(() {
          if (docType == 'idCard') _isUploadingIdCard = false;
          if (docType == 'license') _isUploadingLicense = false;
          if (docType == 'vehicleReg') _isUploadingVehicleReg = false;
        });

        if (uploadRes.success && uploadRes.url != null) {
          setState(() {
            if (docType == 'idCard') {
              _idCardFileName = file.name;
              _idCardPhotoUrl = uploadRes.url;
            } else if (docType == 'license') {
              _licenseFileName = file.name;
              _licenseUrl = uploadRes.url;
            } else if (docType == 'vehicleReg') {
              _vehicleRegFileName = file.name;
              _vehicleRegUrl = uploadRes.url;
            }
          });
        }
      }
    } catch (_) {
      setState(() {
        _isUploadingIdCard = false;
        _isUploadingLicense = false;
        _isUploadingVehicleReg = false;
      });
    }
  }

  Future<void> _pickVehicleAnglePhoto(String angle) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'webp'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          if (angle == 'front') _isUploadingFront = true;
          if (angle == 'back') _isUploadingBack = true;
          if (angle == 'right') _isUploadingRight = true;
          if (angle == 'left') _isUploadingLeft = true;
          if (angle == 'interior') _isUploadingInterior = true;
        });

        final uploadRes = await UploadService().uploadFile(file);
        setState(() {
          if (angle == 'front') _isUploadingFront = false;
          if (angle == 'back') _isUploadingBack = false;
          if (angle == 'right') _isUploadingRight = false;
          if (angle == 'left') _isUploadingLeft = false;
          if (angle == 'interior') _isUploadingInterior = false;
        });

        if (uploadRes.success && uploadRes.url != null) {
          setState(() {
            if (angle == 'front') {
              _photoFrontFileName = file.name;
              _photoFrontUrl = uploadRes.url;
            } else if (angle == 'back') {
              _photoBackFileName = file.name;
              _photoBackUrl = uploadRes.url;
            } else if (angle == 'right') {
              _photoRightFileName = file.name;
              _photoRightUrl = uploadRes.url;
            } else if (angle == 'left') {
              _photoLeftFileName = file.name;
              _photoLeftUrl = uploadRes.url;
            } else if (angle == 'interior') {
              _photoInteriorFileName = file.name;
              _photoInteriorUrl = uploadRes.url;
            }
          });
        }
      }
    } catch (_) {
      setState(() {
        _isUploadingFront = false;
        _isUploadingBack = false;
        _isUploadingRight = false;
        _isUploadingLeft = false;
        _isUploadingInterior = false;
      });
    }
  }

  Future<void> _pickBankCertificatePdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() => _isUploadingBankPdf = true);
        final uploadRes = await UploadService().uploadFile(file);
        setState(() => _isUploadingBankPdf = false);

        if (uploadRes.success && uploadRes.url != null) {
          setState(() {
            _selectedPdfFileName = file.name;
            _bankCertificatePdfUrl = uploadRes.url;
          });
        }
      }
    } catch (_) {
      setState(() => _isUploadingBankPdf = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToCommission || !_agreeToAntiCash) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب الموافقة على الشروط والأحكام وعمولة المنصة وسياسة منع التعامل النقدي للمتابعة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final payload = {
      'fullName': _fullNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : (auth.user?['phoneNumber'] ?? '+966593355884'),
      'nationalId': _nationalIdController.text.trim(),
      'profilePictureUrl': _personalPhotoUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      'idCardPhotoUrl': _idCardPhotoUrl ?? 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=600',
      'driverLicenseUrl': _licenseUrl ?? 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=600',
      'vehicleRegistrationUrl': _vehicleRegUrl ?? 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=600',
      'vehicleBrand': _brandController.text.trim(),
      'vehicleModel': _modelController.text.trim(),
      'vehicleYear': int.tryParse(_yearController.text.trim()) ?? 2024,
      'plateNumber': _plateController.text.trim(),
      'capacity': _capacity,
      'isAirConditioned': _isAirConditioned,
      'photoFrontUrl': _photoFrontUrl ?? 'https://images.unsplash.com/photo-1550355291-bbee04a92027?w=600',
      'photoBackUrl': _photoBackUrl ?? 'https://images.unsplash.com/photo-1550355291-bbee04a92027?w=600',
      'photoRightUrl': _photoRightUrl ?? 'https://images.unsplash.com/photo-1550355291-bbee04a92027?w=600',
      'photoLeftUrl': _photoLeftUrl ?? 'https://images.unsplash.com/photo-1550355291-bbee04a92027?w=600',
      'photoInteriorUrl': _photoInteriorUrl ?? 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?w=600',
      'bankName': _bankNameController.text.trim(),
      'iban': _ibanController.text.trim().toUpperCase(),
      'bankAccountHolderName': _accountHolderController.text.trim().isNotEmpty
          ? _accountHolderController.text.trim()
          : _fullNameController.text.trim(),
      'bankCertificatePdfUrl': _bankCertificatePdfUrl ?? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    };

    final success = await auth.completeDriverProfile(payload);
    setState(() => _isLoading = false);

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('تم استلام طلبك بنجاح!'),
            ],
          ),
          content: const Text(
            'تم تسجيل بياناتك ومركبتك والموافقة على الشروط والأحكام.\n\nطلبك الآن قيد المراجعة السريعة من فريق إدارة منصة ترحيل. يمكنك في هذه الأثناء تصفح سوق الطلبات ومشاهدة المشاوير المتاحة.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const DriverMainScreen()),
                  (route) => false,
                );
              },
              child: const Text('الانتقال لسوق المشاوير'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'فشل إرسال البيانات، يرجى مراجعة الحقول'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استكمال متطلبات تسجيل السائق'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'أنت على بعد خطوة واحدة من بدء تقديم العروض وتحقيق دخل مميز مع ترحيل!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Personal Info & ID
                _buildSectionHeader('1. البيانات الشخصية وصورة الهوية', Icons.badge_rounded),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'الاسم الثلاثي أو الرباعي كابتن', prefixIcon: Icon(Icons.person)),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'يرجى إدخال الاسم كاملاً' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nationalIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رقم الهوية الوطنية أو الإقامة (10 أرقام)', prefixIcon: Icon(Icons.numbers)),
                  validator: (v) => (v == null || v.trim().length != 10) ? 'رقم الهوية يجب أن يكون 10 أرقام' : null,
                ),
                const SizedBox(height: 12),

                // Uploads Personal & ID & License
                _buildUploadButton('الصورة الشخصية للكابتن', _personalPhotoFileName, _isUploadingPersonal, _pickPersonalPhotoFile),
                const SizedBox(height: 8),
                _buildUploadButton('صورة الهوية الوطنية من أبشر', _idCardFileName, _isUploadingIdCard, () => _pickDocumentFile('idCard')),
                const SizedBox(height: 8),
                _buildUploadButton('صورة رخصة القيادة السارية', _licenseFileName, _isUploadingLicense, () => _pickDocumentFile('license')),
                const SizedBox(height: 8),
                _buildUploadButton('صورة استمارة رخصة سير المركبة', _vehicleRegFileName, _isUploadingVehicleReg, () => _pickDocumentFile('vehicleReg')),

                const SizedBox(height: 28),

                // 2. Vehicle Details
                _buildSectionHeader('2. بيانات المركبة وصورها من كافة الجوانب', Icons.directions_car_rounded),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(labelText: 'الشركة (مثل: تويوتا)'),
                        validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(labelText: 'الموديل (مثل: كامري)'),
                        validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'سنة الصنع'),
                        validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _plateController,
                        decoration: const InputDecoration(labelText: 'رقم اللوحة (أ ب ج 1234)'),
                        validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5 Angles
                _buildUploadButton('صورة السيارة من الأمام', _photoFrontFileName, _isUploadingFront, () => _pickVehicleAnglePhoto('front')),
                const SizedBox(height: 8),
                _buildUploadButton('صورة السيارة من الخلف', _photoBackFileName, _isUploadingBack, () => _pickVehicleAnglePhoto('back')),
                const SizedBox(height: 8),
                _buildUploadButton('صورة السيارة من الجانب الأيمن', _photoRightFileName, _isUploadingRight, () => _pickVehicleAnglePhoto('right')),
                const SizedBox(height: 8),
                _buildUploadButton('صورة السيارة من الجانب الأيسر', _photoLeftFileName, _isUploadingLeft, () => _pickVehicleAnglePhoto('left')),
                const SizedBox(height: 8),
                _buildUploadButton('صورة المقاعد الداخلية والمكيف (تظهر للعميل عند القبول)', _photoInteriorFileName, _isUploadingInterior, () => _pickVehicleAnglePhoto('interior')),

                const SizedBox(height: 28),

                // 3. Bank Account
                _buildSectionHeader('3. الحساب البنكي لتحويل الأرباح (IBAN)', Icons.account_balance_rounded),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(labelText: 'اسم البنك المعتمد', prefixIcon: Icon(Icons.account_balance)),
                  validator: (v) => (v == null || v.isEmpty) ? 'اسم البنك مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ibanController,
                  decoration: const InputDecoration(labelText: 'رقم الآيبان البنكي (SA...)', prefixIcon: Icon(Icons.credit_card)),
                  validator: (v) => (v == null || !v.trim().toUpperCase().startsWith('SA') || v.trim().length < 24) ? 'صيغة الآيبان غير صحيحة (SA...)' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountHolderController,
                  decoration: const InputDecoration(labelText: 'اسم صاحب الحساب البنكي مطابقة للآيبان', prefixIcon: Icon(Icons.badge)),
                  validator: (v) => (v == null || v.isEmpty) ? 'اسم صاحب الحساب مطلوب' : null,
                ),
                const SizedBox(height: 12),
                _buildUploadButton('شهادة الآيبان أو إثبات الحساب البنكي PDF', _selectedPdfFileName, _isUploadingBankPdf, _pickBankCertificatePdf),

                const SizedBox(height: 28),

                // 4. Terms & Conditions Checkboxes
                _buildSectionHeader('4. الإقرارات والشروط والأحكام الرسمية', Icons.gavel_rounded),
                const SizedBox(height: 12),

                CheckboxListTile(
                  value: _agreeToCommission,
                  onChanged: (v) => setState(() => _agreeToCommission = v ?? false),
                  title: const Text(
                    'أقر وأوافق على أن منصة ترحيل تخصم 13.50% كعمولة تشغيلية، وتحويل صافي مستحقاتي (86.50%) إلى حسابي البنكي المعتمد بعد إتمام الرحلات.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                ),

                CheckboxListTile(
                  value: _agreeToAntiCash,
                  onChanged: (v) => setState(() => _agreeToAntiCash = v ?? false),
                  title: const Text(
                    'أتعهد تعهداً قاطعاً بعدم طلب أو استلام أي مبالغ نقدية من الركاب مباشرة، والالتزام بضمان المنصة تحت طائلة إيقاف الحساب فوراً.',
                    style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.warning),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                ),

                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('قراءة وثيقة الشروط والأحكام الكاملة لمنصة ترحيل'),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('تأكيد وإرسال متطلبات التسجيل للاعتماد'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildUploadButton(String label, String? fileName, bool isUploading, VoidCallback onTap) {
    final isUploaded = fileName != null;
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUploaded ? AppColors.success : AppColors.cardBorder,
            width: isUploaded ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUploaded ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
              color: isUploaded ? AppColors.success : AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  if (fileName != null)
                    Text(fileName, style: const TextStyle(fontSize: 11, color: AppColors.success), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isUploading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Text(
                isUploaded ? 'تم الرفع' : 'رفع الملف',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUploaded ? AppColors.success : AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
