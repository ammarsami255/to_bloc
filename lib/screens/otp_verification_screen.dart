import 'package:flutter/material.dart';

import 'package:el_moza3/Constants.dart';
import 'package:el_moza3/screens/home_screen.dart';
import 'package:el_moza3/services/auth_service.dart';
import 'package:el_moza3/services/error_handler.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.email});

  static const String id = 'OtpVerificationScreen';

  final String email;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerifying = false;
  int _resendCountdown = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Send verification email using Firebase
  Future<void> _resendEmail() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      final success = await AuthService.sendVerificationEmail();

      if (!mounted) return;
      setState(() => _isResending = false);

      if (success) {
        setState(() {
          _resendCountdown = 60;
        });
        _startCountdown();
        ErrorHandler.showSuccessDialog(
          context,
          message: 'A new verification email has been sent to ${widget.email}',
        );
      } else {
        ErrorHandler.showErrorDialog(
          context,
          message: 'Failed to send verification email. Please try again.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResending = false);
      ErrorHandler.handleException(context, error);
    }
  }

  /// Check verification status using user.reload() and user.emailVerified
  Future<void> checkVerification() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final result = await AuthService.checkVerificationStatus();

      if (!mounted) return;
      setState(() => _isVerifying = false);

      if (result.isSuccess) {
        // Navigate to main screen on success
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else if (result.requiresVerification) {
        ErrorHandler.showInfoDialog(
          context,
          message: result.infoMessage ?? 'Email not verified yet.',
          title: 'Verification Required',
        );
      } else {
        ErrorHandler.showErrorDialog(
          context,
          message: result.errorMessage ?? 'Check failed',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ErrorHandler.handleException(context, error);
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _resendCountdown <= 0) return;
      setState(() => _resendCountdown--);
      _startCountdown();
    });
  }

  /// Sign out
  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Email',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.spacing20),
                _buildHeaderIcon(),
                const SizedBox(height: AppSizes.spacing20),
                _buildInstructions(),
                const SizedBox(height: AppSizes.spacing32),
                _buildVerifyNowButton(),
                const SizedBox(height: AppSizes.spacing12),
                _buildResendButton(),
                const SizedBox(height: AppSizes.spacing12),
                _buildSignOutLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryFade,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mark_email_unread_outlined,
          size: 40,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        const Text(
          'Check your email to verify your account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Text(
          widget.email,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Container(
          padding: const EdgeInsets.all(AppSizes.spacing12),
          decoration: BoxDecoration(
            color: AppColors.primaryLighter,
            borderRadius: AppBorders.radiusMedium,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'We sent a verification link to your email. Click the link to verify your account.',
                  style: TextStyle(fontSize: 13, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyNowButton() {
    return _AnimatedButton(
      isLoading: _isVerifying,
      onPressed: _isVerifying ? null : checkVerification,
      backgroundColor: AppColors.primary,
      child: _isVerifying
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.white),
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'I have verified',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResendButton() {
    return _AnimatedButton(
      isLoading: _isResending,
      onPressed: (_isResending || _resendCountdown > 0) ? null : _resendEmail,
      backgroundColor: AppColors.surface,
      borderSide: const BorderSide(color: AppColors.primary),
      child: _isResending
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  color: _resendCountdown > 0
                      ? AppColors.textSecondary
                      : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _resendCountdown > 0
                      ? 'Resend Email ($_resendCountdown)'
                      : 'Resend Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _resendCountdown > 0
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSignOutLink() {
    return TextButton(
      onPressed: _isLoading ? null : _logout,
      child: const Text(
        'Sign out',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

/// Animated button with press effect
class _AnimatedButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final BorderSide? borderSide;
  final Widget child;

  const _AnimatedButton({
    required this.isLoading,
    required this.onPressed,
    required this.backgroundColor,
    this.borderSide,
    required this.child,
  });

  @override
  State<_AnimatedButton> createState() => __AnimatedButtonState();
}

class __AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: AppSizes.buttonHeight,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: AppBorders.radiusMedium,
            border: widget.borderSide != null
                ? Border.fromBorderSide(widget.borderSide!)
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppBorders.radiusMedium,
              onTap: widget.onPressed,
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
