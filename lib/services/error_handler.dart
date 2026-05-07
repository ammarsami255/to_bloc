import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Global navigator key for showing dialogs from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Centralized error handling service
class ErrorHandler {
  ErrorHandler._();

  static BuildContext? get _context => navigatorKey.currentContext;

  /// Show error modal dialog - small centered card
  static void showErrorDialog(
    BuildContext? context, {
    required String message,
    String title = 'Something went wrong',
  }) {
    final ctx = context ?? _context;
    if (ctx == null) {
      debugPrint('ErrorHandler: No context available');
      return;
    }
    _showCompactDialog(ctx, title: title, message: message, isError: true);
  }

  /// Show success message modal
  static void showSuccessDialog(
    BuildContext? context, {
    required String message,
    String title = 'Success',
  }) {
    final ctx = context ?? _context;
    if (ctx == null) return;
    _showCompactDialog(ctx, title: title, message: message, isSuccess: true);
  }

  /// Show info message modal
  static void showInfoDialog(
    BuildContext? context, {
    required String message,
    String title = 'Info',
  }) {
    final ctx = context ?? _context;
    if (ctx == null) return;
    _showCompactDialog(ctx, title: title, message: message);
  }

  /// Show compact centered dialog (320px width)
  static void _showCompactDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isError = false,
    bool isSuccess = false,
  }) {
    final Color color = isError
        ? Colors.red.shade600
        : isSuccess
        ? Colors.green.shade600
        : Colors.blue.shade600;

    final IconData icon = isError
        ? Icons.error_rounded
        : isSuccess
        ? Icons.check_circle_rounded
        : Icons.info_rounded;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                // OK Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

  /// Handle any exception and show appropriate error message
  static Future<void> handleException(
    BuildContext? context,
    dynamic error,
  ) async {
    debugPrint('ErrorHandler caught: $error');

    String userMessage;

    if (error is FirebaseAuthException) {
      userMessage = _mapAuthError(error.code);
    } else if (error is FirebaseException) {
      userMessage = _mapFirestoreError(error.code);
    } else if (error is FormatException) {
      userMessage = 'Invalid data format. Please check your input.';
    } else if (error is NetworkException) {
      userMessage = 'Network error. Please check your connection.';
    } else if (error is Exception) {
      userMessage = 'Something went wrong. Please try again.';
    } else {
      userMessage = 'An unexpected error occurred.';
    }

    if (context != null) {
      showErrorDialog(context, message: userMessage);
    } else if (_context != null) {
      showErrorDialog(_context, message: userMessage);
    } else {
      debugPrint('ERROR MODAL: $userMessage');
    }
  }

  static String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication error. Please try again.';
    }
  }

  static String _mapFirestoreError(String code) {
    switch (code) {
      case 'not-found':
        return 'The requested document was not found.';
      case 'permission-denied':
        return 'Permission denied.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      default:
        return 'Database error. Please try again.';
    }
  }
}

/// Custom exception for network errors
class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error occurred']);

  @override
  String toString() => message;
}
