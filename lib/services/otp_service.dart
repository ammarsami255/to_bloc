import 'package:cloud_functions/cloud_functions.dart';

/// OTP Service using Firebase Functions only
/// All OTP operations are server-side only - no client-side storage
class OtpService {
  OtpService._();

  // These require Firebase Functions to be deployed
  // The server-side functions handle OTP generation, storage, and verification
  /// Request OTP via email - calls server-side function
  /// Returns the OTP ID for verification
  static Future<String?> sendOtp(String email) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (!_isValidEmail(trimmedEmail)) {
      throw ArgumentError('Invalid email format');
    }

    // Call server-side function
    // The function handles rate limiting and OTP generation
    final functions = FirebaseFunctions.instance.httpsCallable(
      'sendEmailOtpUnauthenticated',
    );

    final result = await functions.call({'email': trimmedEmail});

    if (result.data['success'] == true) {
      return result.data['otpId'] as String?;
    }

    throw Exception('Failed to send OTP');
  }

  /// Verify OTP - calls server-side function
  static Future<bool> verifyOtp({
    required String otpId,
    required String otp,
    required String email,
  }) async {
    if (otp.length != 6) return false;

    final trimmedEmail = email.trim().toLowerCase();

    // Call server-side function for verification
    final functions = FirebaseFunctions.instance.httpsCallable(
      'verifyEmailOtpUnauthenticated',
    );

    try {
      final result = await functions.call({
        'otpId': otpId,
        'otp': otp,
        'email': trimmedEmail,
      });
      return result.data['success'] == true;
    } catch (e) {
      // Function throws on failure - handle gracefully
      return false;
    }
  }

  /// Check if email is valid
  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
