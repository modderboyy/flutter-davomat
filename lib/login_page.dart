import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:DavomatYettilik/main.dart';
import 'package:DavomatYettilik/admin.dart';
import 'package:DavomatYettilik/from_bolt/theme.dart';
import 'package:DavomatYettilik/from_bolt/modern_components.dart';
import 'package:DavomatYettilik/from_bolt/auth_service.dart';

enum AuthMode { login, register }

class ModernLoginPage extends StatefulWidget {
  final void Function(bool) onLoginSuccess;

  const ModernLoginPage({Key? key, required this.onLoginSuccess})
      : super(key: key);

  @override
  State<ModernLoginPage> createState() => _ModernLoginPageState();
}

class _ModernLoginPageState extends State<ModernLoginPage>
    with TickerProviderStateMixin {
  AuthMode _currentMode = AuthMode.login;
  final _logger = Logger();
  String _currentLanguage = 'en';
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showForgotPassword = false;

  // Localization
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'app_title': 'Attendance',
      'login': 'Sign In',
      'register': 'Sign Up',
      'email_placeholder': 'Email Address',
      'password_placeholder': 'Password',
      'login_button': 'Sign In',
      'forgot_password': 'Forgot Password?',
      'reset_password': 'Reset Password',
      'send_reset_link': 'Send Reset Link',
      'back_to_login': 'Back to Sign In',
      'or_continue_with': 'Or continue with',
      'github': 'GitHub',
      'google': 'Google',
      'modder_auth': 'ModderAuth',
      'coming_soon': 'Coming Soon',
      'email_required': 'Email is required',
      'password_required': 'Password is required',
      'invalid_email': 'Please enter a valid email',
      'password_min_length': 'Password must be at least 6 characters',
      'login_success': 'Login successful',
      'login_error': 'Login failed',
      'reset_email_sent': 'Password reset email sent',
      'reset_email_error': 'Failed to send reset email',
    },
    'uz': {
      'app_title': 'Davomat',
      'login': 'Kirish',
      'register': "Ro'yxatdan o'tish",
      'email_placeholder': 'Email manzil',
      'password_placeholder': 'Parol',
      'login_button': 'Kirish',
      'forgot_password': 'Parolni unutdingizmi?',
      'reset_password': 'Parolni tiklash',
      'send_reset_link': 'Tiklash havolasini yuborish',
      'back_to_login': 'Kirishga qaytish',
      'or_continue_with': 'Yoki davom eting',
      'github': 'GitHub',
      'google': 'Google',
      'modder_auth': 'ModderAuth',
      'coming_soon': 'Tez orada',
      'email_required': 'Email talab qilinadi',
      'password_required': 'Parol talab qilinadi',
      'invalid_email': 'Yaroqli email kiriting',
      'password_min_length': 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak',
      'login_success': 'Muvaffaqiyatli kirildi',
      'login_error': 'Kirishda xatolik',
      'reset_email_sent': 'Parolni tiklash emaili yuborildi',
      'reset_email_error': 'Tiklash emailini yuborishda xatolik',
    },
    'ru': {
      'app_title': 'Посещаемость',
      'login': 'Войти',
      'register': 'Регистрация',
      'email_placeholder': 'Email адрес',
      'password_placeholder': 'Пароль',
      'login_button': 'Войти',
      'forgot_password': 'Забыли пароль?',
      'reset_password': 'Сброс пароля',
      'send_reset_link': 'Отправить ссылку сброса',
      'back_to_login': 'Вернуться к входу',
      'or_continue_with': 'Или продолжить с',
      'github': 'GitHub',
      'google': 'Google',
      'modder_auth': 'ModderAuth',
      'coming_soon': 'Скоро',
      'email_required': 'Email обязателен',
      'password_required': 'Пароль обязателен',
      'invalid_email': 'Введите действительный email',
      'password_min_length': 'Пароль должен содержать минимум 6 символов',
      'login_success': 'Успешный вход',
      'login_error': 'Ошибка входа',
      'reset_email_sent': 'Email для сброса пароля отправлен',
      'reset_email_error': 'Не удалось отправить email сброса',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _initializeAnimations();
    AuthService().loadAccounts();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _setLanguagePreference(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _currentLanguage = language;
    });
  }

  String _translate(String key) {
    return _localizedStrings[_currentLanguage]![key] ??
        _localizedStrings['en']![key]!;
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService().signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      _showSnackBar(_translate('login_success'), isSuccess: true);
      widget.onLoginSuccess(true);
    } else {
      _showSnackBar(result.error ?? _translate('login_error'), isSuccess: false);
    }
  }

  Future<void> _handleGitHubAuth() async {
    setState(() => _isLoading = true);

    final result = _currentMode == AuthMode.login
        ? await AuthService().signInWithGitHub()
        : await AuthService().signUpWithGitHub();

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      widget.onLoginSuccess(true);
    } else {
      _showSnackBar(result.error ?? 'GitHub authentication failed', isSuccess: false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _isLoading = true);

    final result = _currentMode == AuthMode.login
        ? await AuthService().signInWithGoogle()
        : await AuthService().signUpWithGoogle();

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      widget.onLoginSuccess(true);
    } else {
      _showSnackBar(result.error ?? 'Google authentication failed', isSuccess: false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar(_translate('email_required'), isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService().resetPassword(_emailController.text.trim());

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      _showSnackBar(_translate('reset_email_sent'), isSuccess: true);
      setState(() => _showForgotPassword = false);
    } else {
      _showSnackBar(result.error ?? _translate('reset_email_error'), isSuccess: false);
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? ModernTheme.successColor : ModernTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ModernTheme.darkTheme,
      child: Scaffold(
        backgroundColor: ModernTheme.backgroundColor,
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _showForgotPassword
                              ? _buildForgotPasswordForm()
                              : _buildMainContent(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading) LoadingOverlay(isVisible: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ModernTheme.backgroundColor,
            ModernTheme.primaryColor.withOpacity(0.1),
            ModernTheme.secondaryColor.withOpacity(0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ModernTheme.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CupertinoIcons.building_2_fill,
              color: ModernTheme.textPrimary,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Text(
            _translate('app_title'),
            style: TextStyle(
              color: ModernTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          PopupMenuButton<String>(
            icon: Icon(CupertinoIcons.globe, color: ModernTheme.textSecondary),
            onSelected: _setLanguagePreference,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'uz', child: Text("O'zbek")),
              PopupMenuItem(value: 'ru', child: Text('Русский')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildModeSelector(),
        SizedBox(height: 32),
        _buildAuthForm(),
      ],
    );
  }

  Widget _buildModeSelector() {
    return ModernCard(
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentMode = AuthMode.login),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _currentMode == AuthMode.login
                      ? ModernTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _translate('login'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _currentMode == AuthMode.login
                        ? ModernTheme.textPrimary
                        : ModernTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentMode = AuthMode.register),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _currentMode == AuthMode.register
                      ? ModernTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _translate('register'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _currentMode == AuthMode.register
                        ? ModernTheme.textPrimary
                        : ModernTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return ModernCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentMode == AuthMode.login) ...[
              ModernTextField(
                controller: _emailController,
                label: _translate('email_placeholder'),
                prefixIcon: CupertinoIcons.mail,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _translate('email_required');
                  }
                  if (!value.contains('@')) {
                    return _translate('invalid_email');
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ModernTextField(
                controller: _passwordController,
                label: _translate('password_placeholder'),
                prefixIcon: CupertinoIcons.lock,
                suffixIcon: _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _translate('password_required');
                  }
                  if (value.length < 6) {
                    return _translate('password_min_length');
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _showForgotPassword = true),
                  child: Text(
                    _translate('forgot_password'),
                    style: TextStyle(color: ModernTheme.primaryColor),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ModernButton(
                text: _translate('login_button'),
                onPressed: _handleEmailLogin,
                isLoading: _isLoading,
                icon: CupertinoIcons.arrow_right,
              ),
            ],
            SizedBox(height: 24),
            _buildDivider(),
            SizedBox(height: 24),
            _buildSocialButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildForgotPasswordForm() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _translate('reset_password'),
            style: TextStyle(
              color: ModernTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ModernTextField(
            controller: _emailController,
            label: _translate('email_placeholder'),
            prefixIcon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 24),
          ModernButton(
            text: _translate('send_reset_link'),
            onPressed: _handleForgotPassword,
            isLoading: _isLoading,
            icon: CupertinoIcons.paperplane,
          ),
          SizedBox(height: 16),
          ModernButton(
            text: _translate('back_to_login'),
            onPressed: () => setState(() => _showForgotPassword = false),
            isOutlined: true,
            icon: CupertinoIcons.back,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: ModernTheme.textTertiary)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _translate('or_continue_with'),
            style: TextStyle(color: ModernTheme.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: ModernTheme.textTertiary)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        ModernButton(
          text: _translate('github'),
          onPressed: _handleGitHubAuth,
          icon: CupertinoIcons.device_laptop,
          backgroundColor: Color(0xFF24292e),
        ),
        SizedBox(height: 12),
        ModernButton(
          text: _translate('google'),
          onPressed: _handleGoogleAuth,
          icon: CupertinoIcons.globe,
          backgroundColor: Color(0xFF4285f4),
        ),
        SizedBox(height: 12),
        ModernButton(
          text: '${_translate('modder_auth')} (${_translate('coming_soon')})',
          onPressed: null,
          icon: CupertinoIcons.star,
          backgroundColor: ModernTheme.textTertiary,
        ),
      ],
    );
  }
}