import 'package:flutter/material.dart';
import 'package:el_moza3/Constants.dart';
import 'package:el_moza3/services/auth_service.dart';
import 'package:el_moza3/services/chat_service.dart';
import 'package:el_moza3/screens/services_screen.dart';
import 'package:el_moza3/screens/search_screen.dart';
import 'package:el_moza3/screens/add_service_screen.dart';
import 'package:el_moza3/screens/chat_screen.dart';
import 'package:el_moza3/screens/profile_screen.dart';
import 'package:el_moza3/screens/otp_verification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  late Stream<int> _unreadChatsStream;

  @override
  void initState() {
    super.initState();
    _unreadChatsStream = ChatService.getUnreadChatsStream();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requireLogin() async {
    if (AuthService.currentUser == null) {
      _showAuthBottomSheet();
      return;
    }

    final isVerified = await AuthService.isCurrentUserVerified();
    if (!isVerified && mounted) {
      final email = AuthService.currentUser?.email;
      if (email != null && email.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(email: email),
          ),
        );
        if (mounted) setState(() {});
      }
    }
  }

  void _showAuthBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AuthBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background2,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background2,
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 1:
        return SearchScreen(onRequireLogin: _requireLogin);
      case 2:
        return AddServiceScreen(
          onClose: () => setState(() => _currentIndex = 0),
        );
      case 3:
        return const ChatScreen();
      case 4:
        return ProfileScreen(
          onRequireLogin: _requireLogin,
          hasVerifiedSession: true,
        );
      case 0:
      default:
        return ServicesScreen(onRequireLogin: _requireLogin);
    }
  }

  Widget _buildLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppBorders.radiusMedium,
      ),
      child: const Icon(Icons.storefront, color: Colors.white, size: 32),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, "رئيسية"),
              _buildNavItem(1, Icons.search_rounded, "بحث"),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(
                3,
                Icons.chat_bubble_outline_rounded,
                "رسائل",
                showBadge: true,
              ),
              _buildNavItem(4, Icons.person_outline_rounded, "حسابي"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    bool showBadge = false,
  }) {
    final selected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () async {
          if (index == 2 || index == 3) {
            await _requireLogin();
            final isVerified = await AuthService.isCurrentUserVerified();
            if (!isVerified) return;
          }
          setState(() => _currentIndex = index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
                if (showBadge && index == 3)
                  StreamBuilder<int>(
                    stream: _unreadChatsStream,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: -8,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            count > 9 ? '9+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await _requireLogin();
            final isVerified = await AuthService.isCurrentUserVerified();
            if (isVerified && mounted) {
              setState(() => _currentIndex = 2);
            }
          },
          borderRadius: BorderRadius.circular(28),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

/// Auth Bottom Sheet for login/register
class AuthBottomSheet extends StatelessWidget {
  const AuthBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'مرحباً بك',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'سجل دخولك أو أنشئ حساب جديد',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          _buildAuthButton(context, 'تسجيل الدخول', Icons.login_rounded, () {
            Navigator.pop(context);
            _showLoginScreen(context);
          }),
          const SizedBox(height: 12),
          _buildGoogleButton(context),
          const SizedBox(height: 12),
          _buildAuthButton(context, 'إنشاء حساب', Icons.person_add_rounded, () {
            Navigator.pop(context);
            _showRegisterScreen(context);
          }, isPrimary: false),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ربما لاحقاً',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildAuthButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isPrimary = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorders.radiusMedium,
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorders.radiusMedium,
                ),
              ),
            ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          Navigator.pop(context);
          final result = await AuthService.signInWithGoogle();
          if (result.isSuccess && context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          } else if (!result.isSuccess && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage ?? 'Google sign-in failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        icon: const Icon(Icons.g_mobiledata, size: 24),
        label: const Text('Continue with Google'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusMedium),
        ),
      ),
    );
  }

  void _showLoginScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showRegisterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _showError('يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await AuthService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (result.isSuccess) {
        Navigator.pop(context);
      } else if (result.requiresVerification) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpVerificationScreen(email: _emailCtrl.text.trim()),
          ),
        );
      } else {
        _showError(result.errorMessage ?? 'فشل تسجيل الدخول');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('حدث خطأ يرجى المحاولة مرة أخرى');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusSmall),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildLogo(),
            const SizedBox(height: 32),
            const Text(
              'تسجيل الدخول',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'ادخل بياناتك للدخول',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _emailCtrl,
              hint: 'البريد الإلكتروني',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passCtrl,
              hint: 'كلمة المرور',
              icon: Icons.lock_outline,
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  // Forgot password
                },
                child: const Text(
                  'نسيت كلمة المرور؟',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.radiusMedium,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ليس لديك حساب؟',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    'إنشاء حساب',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppBorders.radiusLarge,
        ),
        child: const Icon(Icons.storefront, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppBorders.radiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorders.radiusMedium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorders.radiusMedium,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

// Register Screen
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      _showError('يرجى إدخال جميع البيانات المطلوبة');
      return;
    }

    if (_passCtrl.text != _confirmCtrl.text) {
      _showError('كلمات المرور غير متطابقة');
      return;
    }

    if (_passCtrl.text.length < 6) {
      _showError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await AuthService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (result.isSuccess || result.requiresVerification) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpVerificationScreen(email: _emailCtrl.text.trim()),
          ),
        );
      } else {
        _showError(result.errorMessage ?? 'فشل إنشاء الحساب');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('حدث خطأ يرجى المحاولة مرة أخرى');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusSmall),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLogo(),
            const SizedBox(height: 24),
            const Text(
              'إنشاء حساب',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'انضم إلى مجتمعنا',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _nameCtrl,
              hint: 'الاسم الكامل',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailCtrl,
              hint: 'البريد الإلكتروني',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passCtrl,
              hint: 'كلمة المرور',
              icon: Icons.lock_outline,
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmCtrl,
              hint: 'تأكيد كلمة المرور',
              icon: Icons.lock_outline,
              obscure: _obscure,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.radiusMedium,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'لديك حساب بالفعل؟',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppBorders.radiusLarge,
        ),
        child: const Icon(Icons.storefront, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppBorders.radiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorders.radiusMedium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorders.radiusMedium,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
