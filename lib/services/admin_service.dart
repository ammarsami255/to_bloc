import 'package:firebase_auth/firebase_auth.dart';

/// Admin Service - handles admin authentication checks
/// Note: This service uses Firebase Auth custom claims for admin verification
/// Actual admin verification is done server-side
class AdminService {
  AdminService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if current user is an admin via custom claims
  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult();
    return token.claims?['admin'] == true;
  }

  /// Require admin - throws if not admin
  /// This should be called from a secure context (Flutter app)
  static Future<void> requireAdmin() async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }
  }
}
