import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'legal_screen.dart';
import 'root_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignup = false;
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _enterApp() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootShell()),
      (route) => false,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (_isSignup) {
        await auth.signUp(
          email: _contactController.text.trim(),
          password: _passwordController.text,
          data: {'name': _nameController.text.trim()},
        );
      } else {
        await auth.signInWithPassword(
          email: _contactController.text.trim(),
          password: _passwordController.text,
        );
      }
      _enterApp();
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInAnonymously();
      _enterApp();
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Home',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      TextSpan(
                        text: 'Lao',
                        style: TextStyle(color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignup
                      ? 'ສ້າງບັນຊີໃໝ່ເພື່ອເລີ່ມຕົ້ນ'
                      : 'ຍິນດີຕ້ອນຮັບກັບຄືນ',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                if (_isSignup) ...[
                  _FieldLabel('ຊື່ ແລະ ນາມສະກຸນ'),
                  const SizedBox(height: 8),
                  _AppTextField(
                    controller: _nameController,
                    hint: 'ສົມສະໜຸກ ພົມມະຈັນ',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'ກະລຸນາປ້ອນຊື່'
                        : null,
                  ),
                  const SizedBox(height: 18),
                ],
                _FieldLabel('ອີເມວ ຫຼື ເບີໂທລະສັບ'),
                const SizedBox(height: 8),
                _AppTextField(
                  controller: _contactController,
                  hint: 'you@example.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'ກະລຸນາປ້ອນອີເມວ ຫຼື ເບີໂທ'
                      : null,
                ),
                const SizedBox(height: 18),
                _FieldLabel('ລະຫັດຜ່ານ'),
                const SizedBox(height: 8),
                _AppTextField(
                  controller: _passwordController,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ໂຕ'
                      : null,
                  suffix: InkWell(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Tooltip(
                      message: _obscurePassword
                          ? 'ສະແດງລະຫັດຜ່ານ'
                          : 'ເຊື່ອງລະຫັດຜ່ານ',
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 19,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _loading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isSignup ? 'ສະໝັກສະມາຊິກ' : 'ເຂົ້າສູ່ລະບົບ',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isSignup) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'ການສະໝັກສະມາຊິກໝາຍຄວາມວ່າທ່ານຍອມຮັບ '),
                          TextSpan(
                            text: 'ເງື່ອນໄຂການນຳໃຊ້ ແລະ ນະໂຍບາຍຄວາມເປັນສ່ວນຕົວ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LegalScreen(),
                                ),
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Center(
                  child: InkWell(
                    onTap: () => setState(() => _isSignup = !_isSignup),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: _isSignup
                                ? 'ມີບັນຊີແລ້ວບໍ່? '
                                : 'ຍັງບໍ່ມີບັນຊີບໍ່? ',
                          ),
                          TextSpan(
                            text: _isSignup ? 'ເຂົ້າສູ່ລະບົບ' : 'ສະໝັກສະມາຊິກ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: InkWell(
                    onTap: _loading ? null : _continueAsGuest,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'ເຂົ້າໃຊ້ແບບບໍ່ຕ້ອງລົງທະບຽນ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 19, color: AppColors.textSecondary),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
