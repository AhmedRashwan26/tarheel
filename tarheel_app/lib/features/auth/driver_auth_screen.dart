import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
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

  // Document Uploads
  String _personalPhotoUrl = '/uploads/demo_driver_face.jpg';
  String? _personalPhotoFileName = 'صورة_الكابتن_الشخصية.jpg';

  String _idCardPhotoUrl = '/uploads/demo_absher_id.jpg';
  String? _idCardFileName = 'صورة_الهوية_من_أبشر.jpg';

  String _licenseUrl = '/uploads/demo_license.jpg';
  String? _licenseFileName = 'صورة_رخصة_القيادة_والسير.jpg';

  // Vehicle
  final _brandController = TextEditingController(text: 'تويوتا');
  final _modelController = TextEditingController(text: 'كامري');
  final _yearController = TextEditingController(text: '2024');
  final _plateController = TextEditingController(text: 'أ ب ج 1234');
  int _capacity = 4;
  bool _isAirConditioned = true;

  // 4 Angle Photos
  final String _photoFrontUrl = '/uploads/demo_car_front.jpg';
  final String _photoBackUrl = '/uploads/demo_car_back.jpg';
  final String _photoRightUrl = '/uploads/demo_car_right.jpg';
  final String _photoLeftUrl = '/uploads/demo_car_left.jpg';

  // Bank Details
  final _bankNameController = TextEditingController(text: 'مصرف الراجحي');
  final _ibanController = TextEditingController(text: 'SA0380000000608010167519');
  final _accountHolderController = TextEditingController();
  String _bankCertificatePdfUrl = '/uploads/demo_iban_cert.pdf';
  String? _selectedPdfFileName = 'شهادة_الآيبان_البنكي.pdf';

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
        allowedExtensions: ['jpg', 'png', 'jpeg'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _personalPhotoFileName = result.files.first.name;
          _personalPhotoUrl = '/uploads/${result.files.first.name}';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إرفاق الصورة الشخصية للكابتن: $_personalPhotoFileName')),
          );
        }
      }
    } catch (e) {
      debugPrint('Personal photo picker error: $e');
    }
  }

  Future<void> _pickIdCardFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _idCardFileName = result.files.first.name;
          _idCardPhotoUrl = '/uploads/${result.files.first.name}';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إرفاق صورة الهوية من أبشر: $_idCardFileName')),
          );
        }
      }
    } catch (e) {
      debugPrint('ID file picker error: $e');
    }
  }

  Future<void> _pickLicenseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _licenseFileName = result.files.first.name;
          _licenseUrl = '/uploads/${result.files.first.name}';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إرفاق صورة رخصة السير: $_licenseFileName')),
          );
        }
      }
    } catch (e) {
      debugPrint('License file picker error: $e');
    }
  }

  Future<void> _pickBankCertificatePdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedPdfFileName = result.files.first.name;
          _bankCertificatePdfUrl = '/uploads/${result.files.first.name}';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إرفاق: $_selectedPdfFileName')),
          );
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  Future<void> _handleRegisterDriver() async {
    if (!_registerFormKey.currentState!.validate()) return;

    if (_personalPhotoFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الصورة الشخصية للكابتن إلزامية ومطلوبة للتحقق من هوية السائق لدى الركاب'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_idCardFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إرفاق صورة الهوية الوطنية من أبشر'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_licenseFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إرفاق صورة رخصة السير والقيادة'),
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
      'idCardPhotoUrl': _idCardPhotoUrl,
      'driverLicenseUrl': _licenseUrl,
      'vehicleRegistrationUrl': _licenseUrl,
      'vehicleBrand': _brandController.text.trim(),
      'vehicleModel': _modelController.text.trim(),
      'vehicleYear': int.tryParse(_yearController.text) ?? 2024,
      'plateNumber': _plateController.text.trim(),
      'capacity': _capacity,
      'isAirConditioned': _isAirConditioned,
      'photoFrontUrl': _photoFrontUrl,
      'photoBackUrl': _photoBackUrl,
      'photoRightUrl': _photoRightUrl,
      'photoLeftUrl': _photoLeftUrl,
      'photoInteriorUrl': '/uploads/demo_interior.jpg',
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
            onPressed: _pickPersonalPhotoFile,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _personalPhotoFileName != null ? AppColors.success : AppColors.accent,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            icon: Icon(
              _personalPhotoFileName != null ? Icons.check_circle_rounded : Icons.face_rounded,
              color: _personalPhotoFileName != null ? AppColors.success : AppColors.accent,
            ),
            label: Text(
              _personalPhotoFileName != null
                  ? 'تم إرفاق: $_personalPhotoFileName'
                  : 'رفع الصورة الشخصية للكابتن (إجباري ومطلوب للتحقق)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _personalPhotoFileName != null ? AppColors.success : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Absher ID Upload Button
          OutlinedButton.icon(
            onPressed: _pickIdCardFile,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _idCardFileName != null ? AppColors.success : AppColors.primary,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            icon: Icon(
              _idCardFileName != null ? Icons.check_circle_rounded : Icons.camera_front_rounded,
              color: _idCardFileName != null ? AppColors.success : AppColors.primary,
            ),
            label: Text(
              _idCardFileName != null
                  ? 'تم إرفاق: $_idCardFileName'
                  : 'رفع صورة الهوية الوطنية من تطبيق أبشر (مطلوب)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _idCardFileName != null ? AppColors.success : AppColors.primary,
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
          _buildSectionHeader('3. صورة رخصة السير وصور السيارة الأربعة', Icons.photo_library_rounded),
          const SizedBox(height: 10),

          // License Upload Button
          OutlinedButton.icon(
            onPressed: _pickLicenseFile,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _licenseFileName != null ? AppColors.success : AppColors.accent,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            icon: Icon(
              _licenseFileName != null ? Icons.check_circle_rounded : Icons.drive_eta_rounded,
              color: _licenseFileName != null ? AppColors.success : AppColors.accent,
            ),
            label: Text(
              _licenseFileName != null
                  ? 'تم إرفاق: $_licenseFileName'
                  : 'رفع صورة رخصة السير والقيادة (مطلوب)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _licenseFileName != null ? AppColors.success : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'صور السيارة من الجهات الأربع لاعتماد الحساب:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPhotoBox('أمام', Icons.arrow_upward_rounded),
              const SizedBox(width: 8),
              _buildPhotoBox('خلف', Icons.arrow_downward_rounded),
              const SizedBox(width: 8),
              _buildPhotoBox('يمين', Icons.arrow_forward_rounded),
              const SizedBox(width: 8),
              _buildPhotoBox('يسار', Icons.arrow_back_rounded),
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
            onPressed: _pickBankCertificatePdf,
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent),
            label: Text(
              _selectedPdfFileName != null
                  ? 'تم إرفاق: $_selectedPdfFileName'
                  : 'إرفاق شهادة الآيبان البنكي (ملف PDF)',
              style: const TextStyle(fontSize: 13),
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

  Widget _buildPhotoBox(String label, IconData icon) {
    return Expanded(
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                SizedBox(width: 2),
                Text('مرفقة', style: TextStyle(fontSize: 9, color: AppColors.success)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
