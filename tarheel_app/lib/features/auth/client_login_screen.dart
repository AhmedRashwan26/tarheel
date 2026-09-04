import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';

class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key});

  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Login Controllers
  final _loginIdentifierController = TextEditingController();
  String _selectedChannel = 'WHATSAPP'; // 'WHATSAPP', 'SMS', 'EMAIL'
  
  // Register Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdentifierController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isEmailInput {
    final text = _loginIdentifierController.text.trim();
    return text.contains('@');
  }

  bool get _isPhoneInput {
    final text = _loginIdentifierController.text.trim();
    if (text.isEmpty) return false;
    return !text.contains('@') && RegExp(r'^[0-9+]+$').hasMatch(text);
  }

  void _onLoginIdentifierChanged(String value) {
    setState(() {
      final text = value.trim();
      if (text.contains('@')) {
        // Automatically switch to Email channel
        _selectedChannel = 'EMAIL';
      } else if (text.isNotEmpty && RegExp(r'^[0-9+]+$').hasMatch(text)) {
        // If it's a phone number and previous was Email, switch to WhatsApp
        if (_selectedChannel == 'EMAIL') {
          _selectedChannel = 'WHATSAPP';
        }
      }
    });
  }

  Future<void> _handleLogin() async {
    final identifier = _loginIdentifierController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الجوال أو البريد الإلكتروني')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.setRole('CLIENT');
    final success = await auth.sendOtp(identifier, channel: _selectedChannel, role: 'CLIENT');
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            identifier: identifier,
            isRegistration: false,
            role: 'CLIENT',
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

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الاسم الكامل')),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الجوال')),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال البريد الإلكتروني')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.setRole('CLIENT');
    final success = await auth.registerClient(
      fullName: fullName,
      phoneNumber: phone,
      email: email,
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      await auth.sendOtp(phone, channel: 'WHATSAPP', role: 'CLIENT');
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              identifier: phone,
              isRegistration: true,
              role: 'CLIENT',
            ),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'فشل إنشاء الحساب'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دخول الركاب والعملاء'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Header
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 110,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'حياك الله في ترحيل',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                    Tab(text: 'إنشاء حساب جديد'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 520,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Login Tab
                    _buildLoginTab(),
                    // Register Tab
                    _buildRegisterTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'حياك الله مجدداً!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        const Text(
          'أدخل رقم هاتفك أو بريدك الإلكتروني لاستلام رمز التحقق',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _loginIdentifierController,
          keyboardType: TextInputType.emailAddress,
          onChanged: _onLoginIdentifierChanged,
          decoration: const InputDecoration(
            labelText: 'رقم الجوال أو البريد الإلكتروني',
            hintText: '+9665xxxxxxxx أو name@email.com',
            prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          'قناة استلام رمز التحقق المفضلة:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(child: _buildChannelChip('WHATSAPP', 'عبر الواتساب', Icons.chat_bubble_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _buildChannelChip('EMAIL', 'عبر الإيميل', Icons.email_rounded)),
          ],
        ),

        const SizedBox(height: 28),

        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          child: _isLoading
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

  Widget _buildRegisterTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'إنشاء حساب راكب جديد',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        const Text(
          'سجل بياناتك للبدء بنشر المشاوير المجدولة',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'الاسم الكامل',
            hintText: 'الاسم الثلاثي أو الكامل',
            prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'رقم الجوال',
            hintText: '+9665xxxxxxxx',
            prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _isLoading ? null : _handleRegister,
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('إنشاء الحساب ومتابعة التحقق'),
        ),
      ],
    );
  }

  Widget _buildChannelChip(String value, String label, IconData icon) {
    final isEmail = _isEmailInput;
    final isPhone = _isPhoneInput;

    bool isEnabled = true;
    if (isEmail) {
      // If typing email, only EMAIL is enabled
      isEnabled = value == 'EMAIL';
    } else if (isPhone) {
      // If typing phone, only WHATSAPP is enabled (Email is disabled)
      isEnabled = value == 'WHATSAPP';
    }

    final isSelected = _selectedChannel == value && isEnabled;

    return Expanded(
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.35,
        child: InkWell(
          onTap: isEnabled ? () => setState(() => _selectedChannel = value) : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : (isEnabled ? Colors.white : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.accent
                    : (isEnabled ? AppColors.cardBorder : Colors.grey.shade300),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.accent
                      : (isEnabled ? AppColors.textSecondary : Colors.grey.shade400),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppColors.accent
                        : (isEnabled ? AppColors.textSecondary : Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
