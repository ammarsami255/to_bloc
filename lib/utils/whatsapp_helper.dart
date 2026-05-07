import 'package:url_launcher/url_launcher.dart';

/// Centralized WhatsApp helper service
/// Handles phone normalization and URL launching
class WhatsAppHelper {
  /// Normalize phone number for WhatsApp
  ///
  /// - Removes all non-digits
  /// - Removes leading "+"
  /// - Removes leading zeros (Egypt format)
  /// - Returns number WITHOUT country code prefix "+"
  ///
  /// Examples:
  /// - "01123456789" (Egypt local) -> "201123456789"
  /// - "+201123456789" (Egypt) -> "201123456789"
  /// - "+966512345678" (Saudi) -> "966512345678"
  static String normalizePhone(String phone) {
    // Remove all non-digits
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Remove leading +
    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    }

    // Handle Egypt: remove leading 0, add country code
    // Egypt numbers are 11 digits starting with 01
    if (digits.length == 11 && digits.startsWith('20')) {
      // Already has country code, remove leading 0 if present
      digits = digits.substring(2);
      digits = '20$digits';
    } else if (digits.startsWith('0') && digits.length == 11) {
      // Local Egypt number: 011... -> 2011...
      digits = digits.substring(1); // Remove leading 0
      digits = '20$digits';
    }

    return digits;
  }

  /// Build WhatsApp URL for a phone number
  /// Format: https://wa.me/<number>?text=<encoded_message>
  static String buildWhatsAppUrl(String phone, {String? message}) {
    final normalized = normalizePhone(phone);
    String url = 'https://wa.me/$normalized';

    if (message != null && message.isNotEmpty) {
      final encoded = Uri.encodeComponent(message);
      url += '?text=$encoded';
    }

    return url;
  }

  /// Open WhatsApp with a phone number
  /// Returns true if successful, false otherwise
  static Future<bool> openWhatsApp(String phone, {String? message}) async {
    final url = buildWhatsAppUrl(phone, message: message);
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Open WhatsApp with fallback to web if app not available
  static Future<void> openWhatsAppWithFallback(
    String phone, {
    String? message,
    required Function(String) onError,
  }) async {
    final url = buildWhatsAppUrl(phone, message: message);
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try web URL
        final webUrl = buildWhatsAppUrl(phone, message: message);
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      onError('تعذر فتح واتساب');
    }
  }
}
