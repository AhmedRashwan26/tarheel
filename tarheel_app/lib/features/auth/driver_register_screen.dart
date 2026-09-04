import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';
import '../terms/terms_and_conditions_screen.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();

  // Vehicle
  final _brandController = TextEditingController(text: 'تويوتا');
  final _modelController = TextEditingController(text: 'كامري');
  final _yearController = TextEditingController(text: '2023');
  final _plateController = TextEditingController(text: 'أ ب ج 1234');
  int _capacity = 4;
  bool _isAirConditioned = true;

  // 4 Angle Photos URLs (or simulated mock upload URLs)
  String _photoFrontUrl = '/uploads/demo_car_front.jpg';
  String _photoBackUrl = '/uploads/demo_car_back.jpg';
  String _photoRightUrl = '/uploads/demo_car_right.jpg';
  String _photoLeftUrl = '/uploads/demo_car_left.jpg';
  String _vehicleRegUrl = '/uploads/demo_reg.jpg';
  String _licenseUrl = '/uploads/demo_lic.jpg';

  // Bank Details
  final _bankNameController = TextEditingController(text: 'مصرف الراجحي');
  final _ibanController = TextEditingController(text: 'SA0380000000608010167519');
  final _accountHolderController = TextEditingController();
  String _bankCertificatePdfUrl = '/uploads/demo_iban_cert.pdf';
  String? _selectedPdfFileName = 'شهادة_الآيبان_البنكي.pdf';

  // Policy Agreement
  bool _agreeToAntiCashPolicy = false;
  bool _isLoading = false;

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
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToAntiCashPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب الموافقة على شروط ترحيل وعمولة 10% وسياسة منع النقد للمتابعة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final driverPayload = {
      'phoneNumber': _phoneController.text.trim(),
      'fullName': _fullNameController.text.trim(),
      'nationalId': _nationalIdController.text.trim(),
      'idCardPhotoUrl': '/uploads/demo_id.jpg',
      'driverLicenseUrl': _licenseUrl,
      'vehicleRegistrationUrl': _vehicleRegUrl,
      'vehicleBrand': _brandController.text.trim(),
      'vehicleModel': _modelController.text.trim(),
      'vehicleYear': int.tryParse(_yearController.text) ?? 2023,
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
    final success = await auth.registerDriver(driverPayload);
    setState(() => _isLoading = false);

    if (success && mounted) {
      await auth.sendOtp(_phoneController.text.trim(), channel: 'WHATSAPP');
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              identifier: _phoneController.text.trim(),
              isRegistration: true,
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
        title: const Text('تسجيل كابتن / سائق جديد'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('1. البيانات الشخصية والتحقق', Icons.badge_rounded),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل الثلاثي'),
                  validator: (v) => v == null || v.isEmpty ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الجوال (إجباري للسائق)',
                    hintText: '+9665xxxxxxxx',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'رقم الجوال مطلوب للسائق' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nationalIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رقم الهوية الوطنية / الإقامة (10 أرقام)'),
                  validator: (v) => v == null || v.length < 10 ? 'رقم الهوية يجب أن يكون 10 أرقام' : null,
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
                        decoration: const InputDecoration(labelText: 'سنة الصنع (مثال: 2023)'),
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
                  activeColor: AppColors.accent,
                  onChanged: (val) => setState(() => _isAirConditioned = val),
                ),

                const SizedBox(height: 16),
                _buildSectionHeader('3. صور السيارة الأربعة ورخصة السير', Icons.photo_library_rounded),
                const SizedBox(height: 10),
                const Text(
                  'يجب إرفاق صور واضحة لسيارتك من الجهات الأربع لاعتماد الحساب:',
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
                // Clean Terms & Conditions Agreement
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
                        value: _agreeToAntiCashPolicy,
                        activeColor: AppColors.accent,
                        onChanged: (val) => setState(() => _agreeToAntiCashPolicy = val ?? false),
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
                            'أتعهد بالموافقة والالتزام بكافة الشروط والأحكام الخاصة بالمنصة',
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
                  onPressed: _isLoading ? null : _handleRegisterDriver,
                  child: _isLoading
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
          border: Border.all(color: AppColors.accent.withOpacity(0.5)),
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
