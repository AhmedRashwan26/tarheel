import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/upload_service.dart';
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';
import '../terms/terms_and_conditions_screen.dart';

class DriverAuthScreen extends StatefulWidget {
  final int initialTabIndex;

  const DriverAuthScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DriverAuthScreen> createState() => _DriverAuthScreenState();
}

class _DriverAuthScreenState extends State<DriverAuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Controllers
  final _loginPhoneController = TextEditingController();
  String _selectedLoginChannel = 'WHATSAPP';
  bool _isLoginLoading = false;

  // Registration Form Key & Controllers
  final _registerFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();

  // Document Uploads & URLs
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

  // Vehicle
  final _brandController = TextEditingController(text: 'تويوتا');
  final _modelController = TextEditingController(text: 'كامري');
  final _yearController = TextEditingController(text: '2024');
  final _plateController = TextEditingController(text: 'أ ب ج 1234');
  int _capacity = 4;
  bool _isAirConditioned = true;

  // 5 Angle Photos
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

  // Bank Details
  final _bankNameController = TextEditingController(text: 'مصرف الراجحي');
  final _ibanController = TextEditingController(text: 'SA0380000000608010167519');
  final _accountHolderController = TextEditingController();
  String? _bankCertificatePdfUrl;
  String? _selectedPdfFileName;
  bool _isUploadingBankPdf = false;

  // Agreement & Loading
  bool _agreeToTerms = false;
  bool _isRegisterLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneController.dispose();
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
              SnackBar(
                content: Text('✅ تم رفع الصورة الشخصية بنجاح: ${file.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploadRes.errorMessage ?? 'فشل رفع الصورة الشخصية'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingPersonal = false);
      debugPrint('Personal photo picker error: $e');
    }
  }

  Future<void> _pickIdCardFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() => _isUploadingIdCard = true);
        final uploadRes = await UploadService().uploadFile(file);
        setState(() => _isUploadingIdCard = false);

        if (uploadRes.success && uploadRes.url != null) {
          setState(() {
            _idCardFileName = file.name;
            _idCardPhotoUrl = uploadRes.url;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ تم رفع صورة الهوية الوطنية بنجاح: ${file.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploadRes.errorMessage ?? 'فشل رفع صورة الهوية'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingIdCard = false);
      debugPrint('ID file picker error: $e');
    }
  }

  Future<void> _pickLicenseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() => _isUploadingLicense = true);
        final uploadRes = await UploadService().uploadFile(file);
        setState(() => _isUploadingLicense = false);

        if (uploadRes.success && uploadRes.url != null) {
          setState(() {
            _licenseFileName = file.name;
            _licenseUrl = uploadRes.url;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ تم رفع صورة رخصة القيادة بنجاح: ${file.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploadRes.errorMessage ?? 'فشل رفع رخصة القيادة'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingLicense = false);
      debugPrint('License file picker error: $e');
    }
  }

  Future<void> _pickVehicleRegFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() => _isUploadingVehicleReg = true);
        final uploadRes = await UploadService().uploadFile(file);
        setState(() => _isUploadingVehicleReg = false);

        if (uploadRes.success && uploadRes.url != null) {
          setState(() {
            _vehicleRegFileName = file.name;
            _vehicleRegUrl = uploadRes.url;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ تم رفع استمارة سير المركبة بنجاح: ${file.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploadRes.errorMessage ?? 'فشل رفع استمارة المركبة'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingVehicleReg = false);
      debugPrint('Vehicle reg picker error: $e');
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
            if (angle == 'front') { _photoFrontUrl = uploadRes.url; _photoFrontFileName = file.name; }
            if (angle == 'back') { _photoBackUrl = uploadRes.url; _photoBackFileName = file.name; }
            if (angle == 'right') { _photoRightUrl = uploadRes.url; _photoRightFileName = file.name; }
            if (angle == 'left') { _photoLeftUrl = uploadRes.url; _photoLeftFileName = file.name; }
            if (angle == 'interior') { _photoInteriorUrl = uploadRes.url; _photoInteriorFileName = file.name; }
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ تم رفع صورة السيارة بنجاح: ${file.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploadRes.errorMessage ?? 'فشل رفع صورة السيارة'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingFront = false;
        _isUploadingBack = false;
        _isUploadingRight = false;
        _isUploadingLeft = false;
        _isUploadingInterior = false;
      });
      debugPrint('Vehicle angle photo error: $e');
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ تم رفع إثبات الحساب البنكي بنجاح: ${file.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploadRes.errorMessage ?? 'فشل رفع الملف'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingBankPdf = false);
      debugPrint('Bank cert picker error: $e');
    }
  }

  Future<void> _handleRegisterDriver() async {
    if (!_registerFormKey.currentState!.validate()) return;

    if (_personalPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الصورة الشخصية للكابتن إلزامية ومطلوبة للتحقق من هوية السائق لدى الركاب'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_idCardPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى رفع صورة الهوية الوطنية من أبشر'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_licenseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى رفع صورة رخصة القيادة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_bankCertificatePdfUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إرفاق شهادة الآيبان البنكي أو إثبات الحساب PDF'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى الموافقة على الشروط والأحكام للمتابعة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isRegisterLoading = true);

    final driverPayload = {
      'phoneNumber': _phoneController.text.trim(),
      'fullName': _fullNameController.text.trim(),
      'nationalId': _nationalIdController.text.trim(),
      'profilePictureUrl': _personalPhotoUrl,
      'avatarUrl': _personalPhotoUrl,
      'idCardPhotoUrl': _idCardPhotoUrl,
      'driverLicenseUrl': _licenseUrl,
      'vehicleRegistrationUrl': _vehicleRegUrl ?? _licenseUrl,
      'vehicleBrand': _brandController.text.trim(),
      'vehicleModel': _modelController.text.trim(),
      'vehicleYear': int.tryParse(_yearController.text) ?? 2024,
      'plateNumber': _plateController.text.trim(),
      'capacity': _capacity,
      'isAirConditioned': _isAirConditioned,
      'photoFrontUrl': _photoFrontUrl ?? _licenseUrl,
      'photoBackUrl': _photoBackUrl ?? _photoFrontUrl ?? _licenseUrl,
      'photoRightUrl': _photoRightUrl ?? _photoFrontUrl ?? _licenseUrl,
      'photoLeftUrl': _photoLeftUrl ?? _photoFrontUrl ?? _licenseUrl,
      'photoInteriorUrl': _photoInteriorUrl ?? _photoFrontUrl ?? _licenseUrl,
      'bankName': _bankNameController.text.trim(),
      'iban': _ibanController.text.trim(),
      'bankAccountHolderName': _accountHolderController.text.trim().isNotEmpty
          ? _accountHolderController.text.trim()
          : _fullNameController.text.trim(),
      'bankCertificatePdfUrl': _bankCertificatePdfUrl,
      'agreeToAntiCashPolicy': true,
    };

    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.setRole('DRIVER');
    final success = await auth.registerDriver(driverPayload);
    setState(() => _isRegisterLoading = false);

    if (success && mounted) {
      await auth.sendOtp(_phoneController.text.trim(), channel: 'WHATSAPP', role: 'DRIVER');
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              identifier: _phoneController.text.trim(),
              isRegistration: true,
              role: 'DRIVER',
            ),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'فشل تسجيل بيانات السائق'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دخول الكباتن والسائقين'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Header
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'حياك الله كابتن ترحيل',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Tab Selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(text: 'تسجيل الدخول'),
                    Tab(text: 'تسجيل كابتن جديد'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab Views
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return _tabController.index == 0
                      ? _buildDriverLoginTab()
                      : _buildDriverRegisterTab();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverLoginTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'حياك الله يا كابتن!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        const Text(
          'أدخل رقم جوالك أو بريدك الإلكتروني لاستلام رمز التحقق والدخول لحسابك',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

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
          'قناة استلام رمز التحقق:',
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

        const SizedBox(height: 32),

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
      ],
    );
  }

  Widget _buildLoginChannelChip(String value, String label, IconData icon) {
    final isSelected = _selectedLoginChannel == value;
    return Expanded(
      child: InkWell(
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
      ),
    );
  }

  Widget _buildDriverRegisterTab() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('1. البيانات الشخصية وصورة الهوية من أبشر', Icons.badge_rounded),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'الاسم الكامل الثلاثي'),
            validator: (v) => v == null || v.isEmpty ? 'الاسم مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم الجوال (إلزامي للسائق)',
              hintText: '+9665xxxxxxxx',
            ),
            validator: (v) => v == null || v.isEmpty ? 'رقم الجوال مطلوب للسائق' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nationalIdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'رقم الهوية الوطنية / الإقامة (10 أرقام)'),
            validator: (v) => v == null || v.length < 10 ? 'رقم الهوية يجب أن يكون 10 أرقام' : null,
          ),
          const SizedBox(height: 12),

          // 1. Personal Face Photo Upload Button (Mandatory for drivers)
          OutlinedButton.icon(
            onPressed: _isUploadingPersonal ? null : _pickPersonalPhotoFile,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _personalPhotoUrl != null ? AppColors.success : AppColors.accent,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            icon: _isUploadingPersonal
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    _personalPhotoUrl != null ? Icons.check_circle_rounded : Icons.face_rounded,
                    color: _personalPhotoUrl != null ? AppColors.success : AppColors.accent,
                  ),
            label: Text(
              _isUploadingPersonal
                  ? 'جاري رفع الصورة الشخصية...'
                  : (_personalPhotoFileName != null
                      ? 'تم رفع الصورة الشخصية: $_personalPhotoFileName ✅'
                      : 'رفع الصورة الشخصية للكابتن (إجباري ومطلوب للتحقق)'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _personalPhotoUrl != null ? AppColors.success : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Absher ID Upload Button
          OutlinedButton.icon(
            onPressed: _isUploadingIdCard ? null : _pickIdCardFile,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _idCardPhotoUrl != null ? AppColors.success : AppColors.primary,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            icon: _isUploadingIdCard
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    _idCardPhotoUrl != null ? Icons.check_circle_rounded : Icons.camera_front_rounded,
                    color: _idCardPhotoUrl != null ? AppColors.success : AppColors.primary,
                  ),
            label: Text(
              _isUploadingIdCard
                  ? 'جاري رفع الهوية الوطنية...'
                  : (_idCardFileName != null
                      ? 'تم رفع الهوية: $_idCardFileName ✅'
                      : 'رفع صورة الهوية الوطنية من تطبيق أبشر (مطلوب)'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _idCardPhotoUrl != null ? AppColors.success : AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('2. بيانات ومواصفات المركبة', Icons.directions_car_filled_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(labelText: 'ماركة السيارة (تويوتا، إلخ)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: 'الطراز (كامري، النترا)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سنة الصنع (مثال: 2024)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _plateController,
                  decoration: const InputDecoration(labelText: 'رقم اللوحة'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Capacity Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('عدد الركاب المتاح في السيارة:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_capacity > 1) setState(() => _capacity--);
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                  ),
                  Text(
                    '$_capacity ركاب',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_capacity < 25) setState(() => _capacity++);
                    },
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),

          // Air Condition Toggle
          SwitchListTile(
            title: const Text('السيارة مكيفة (A/C)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('التكييف ميزة أساسية مطلوبة في رحلات ترحيل المجدولة'),
            value: _isAirConditioned,
            activeThumbColor: AppColors.accent,
            onChanged: (val) => setState(() => _isAirConditioned = val),
          ),

          const SizedBox(height: 16),
          _buildSectionHeader('3. رخص القيادة وسير المركبة وصور السيارة الـ 5', Icons.photo_library_rounded),
          const SizedBox(height: 10),

          // License & Istimara Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploadingLicense ? null : _pickLicenseFile,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _licenseUrl != null ? AppColors.success : AppColors.accent,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  ),
                  icon: _isUploadingLicense
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          _licenseUrl != null ? Icons.check_circle_rounded : Icons.drive_eta_rounded,
                          color: _licenseUrl != null ? AppColors.success : AppColors.accent,
                          size: 20,
                        ),
                  label: Text(
                    _isUploadingLicense
                        ? 'جاري الرفع...'
                        : (_licenseUrl != null ? 'رخصة القيادة ✅' : 'رفع رخصة القيادة'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _licenseUrl != null ? AppColors.success : AppColors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploadingVehicleReg ? null : _pickVehicleRegFile,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _vehicleRegUrl != null ? AppColors.success : AppColors.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  ),
                  icon: _isUploadingVehicleReg
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          _vehicleRegUrl != null ? Icons.check_circle_rounded : Icons.badge_rounded,
                          color: _vehicleRegUrl != null ? AppColors.success : AppColors.primary,
                          size: 20,
                        ),
                  label: Text(
                    _isUploadingVehicleReg
                        ? 'جاري الرفع...'
                        : (_vehicleRegUrl != null ? 'الاستمارة ✅' : 'رفع استمارة المركبة'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _vehicleRegUrl != null ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            'صور السيارة الفعلية من الجهات الأربع والمقاعد الداخلية لاعتماد الحساب:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildVehicleAnglePhotoBox(
                label: 'أمام',
                icon: Icons.arrow_upward_rounded,
                photoUrl: _photoFrontUrl,
                fileName: _photoFrontFileName,
                isUploading: _isUploadingFront,
                onTap: () => _pickVehicleAnglePhoto('front'),
              ),
              const SizedBox(width: 6),
              _buildVehicleAnglePhotoBox(
                label: 'خلف',
                icon: Icons.arrow_downward_rounded,
                photoUrl: _photoBackUrl,
                fileName: _photoBackFileName,
                isUploading: _isUploadingBack,
                onTap: () => _pickVehicleAnglePhoto('back'),
              ),
              const SizedBox(width: 6),
              _buildVehicleAnglePhotoBox(
                label: 'يمين',
                icon: Icons.arrow_forward_rounded,
                photoUrl: _photoRightUrl,
                fileName: _photoRightFileName,
                isUploading: _isUploadingRight,
                onTap: () => _pickVehicleAnglePhoto('right'),
              ),
              const SizedBox(width: 6),
              _buildVehicleAnglePhotoBox(
                label: 'يسار',
                icon: Icons.arrow_back_rounded,
                photoUrl: _photoLeftUrl,
                fileName: _photoLeftFileName,
                isUploading: _isUploadingLeft,
                onTap: () => _pickVehicleAnglePhoto('left'),
              ),
              const SizedBox(width: 6),
              _buildVehicleAnglePhotoBox(
                label: 'داخلية',
                icon: Icons.airline_seat_recline_normal_rounded,
                photoUrl: _photoInteriorUrl,
                fileName: _photoInteriorFileName,
                isUploading: _isUploadingInterior,
                onTap: () => _pickVehicleAnglePhoto('interior'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('4. الحساب البنكي لتحويل الأرباح (IBAN & PDF)', Icons.account_balance_rounded),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bankNameController,
            decoration: const InputDecoration(
              labelText: 'اسم البنك (الراجحي، الأهلي، الإنماء، إلخ)',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _ibanController,
            decoration: const InputDecoration(
              labelText: 'رقم الآيبان البنكي (SA...)',
              hintText: 'SA0000000000000000000000',
            ),
            validator: (v) => v == null || !v.startsWith('SA') || v.length < 24
                ? 'يرجى إدخال آيبان سعودي صحيح يبدأ بـ SA (24 خانة)'
                : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _accountHolderController,
            decoration: const InputDecoration(
              labelText: 'اسم صاحب الحساب كما في الشهادة البنكية',
            ),
          ),
          const SizedBox(height: 12),

          // Bank PDF Picker
          OutlinedButton.icon(
            onPressed: _isUploadingBankPdf ? null : _pickBankCertificatePdf,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _bankCertificatePdfUrl != null ? AppColors.success : AppColors.accent,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            icon: _isUploadingBankPdf
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    _bankCertificatePdfUrl != null ? Icons.check_circle_rounded : Icons.picture_as_pdf_rounded,
                    color: _bankCertificatePdfUrl != null ? AppColors.success : AppColors.accent,
                  ),
            label: Text(
              _isUploadingBankPdf
                  ? 'جاري رفع إثبات الحساب البنكي...'
                  : (_selectedPdfFileName != null
                      ? 'تم إرفاق: $_selectedPdfFileName ✅'
                      : 'إرفاق شهادة الآيبان البنكي (ملف PDF أو صورة)'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _bankCertificatePdfUrl != null ? AppColors.success : AppColors.accent,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Clean Terms & Conditions Checkbox
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  activeColor: AppColors.accent,
                  onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
                      );
                    },
                    child: const Text(
                      'أتعهد بالموافقة على الشروط والأحكام الخاصة بمنصة ترحيل',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.accent),
                  tooltip: 'عرض الشروط والأحكام',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isRegisterLoading ? null : _handleRegisterDriver,
            child: _isRegisterLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('إرسال طلب الانضمام والتحقق'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildVehicleAnglePhotoBox({
    required String label,
    required IconData icon,
    required String? photoUrl,
    required String? fileName,
    required bool isUploading,
    required VoidCallback onTap,
  }) {
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    return Expanded(
      child: InkWell(
        onTap: isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: hasPhoto ? AppColors.success.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasPhoto
                  ? AppColors.success
                  : (isUploading ? AppColors.accent : AppColors.cardBorder),
              width: hasPhoto ? 1.8 : 1.2,
            ),
          ),
          child: isUploading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasPhoto ? Icons.check_circle_rounded : icon,
                      size: 22,
                      color: hasPhoto ? AppColors.success : AppColors.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasPhoto ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPhoto ? 'تم الرفع ✅' : 'انقر للرفع',
                      style: TextStyle(
                        fontSize: 9,
                        color: hasPhoto ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
