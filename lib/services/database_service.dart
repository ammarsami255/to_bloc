import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  DatabaseService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  static CollectionReference<Map<String, dynamic>> get _listingsCollection =>
      _firestore.collection('listings');

  static Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
  }) {
    return _usersCollection.doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'isEmailVerified': false,
      'online': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Update user online status
  static Future<void> setUserOnlineStatus(String uid, bool isOnline) async {
    await _usersCollection.doc(uid).update({
      'online': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    final snapshot = await _usersCollection.doc(uid).get();
    return snapshot.data();
  }

  static Stream<Map<String, dynamic>?> watchUserDocument(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      return snapshot.data();
    });
  }

  /// Get user name by ID (for chat avatars)
  static Future<String> getUserName(String uid) async {
    final user = await getUserDocument(uid);
    return user?['name'] as String? ?? 'User';
  }

  /// Get user profile image URL by ID
  static Future<String?> getUserProfileImage(String uid) async {
    final user = await getUserDocument(uid);
    return user?['profileImage'] as String?;
  }

  /// Check if user's email is verified
  ///优先检查Firebase Auth状态,再检查Firestore
  static Future<bool> isUserEmailVerified(String uid) async {
    // 先检查Firebase Auth的验证状态
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.emailVerified) {
      return true;
    }
    // 再检查Firestore的自定义验证状态
    final user = await getUserDocument(uid);
    return user?['isEmailVerified'] == true;
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? companyName,
    String? address,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (companyName != null) updates['companyName'] = companyName;
    if (address != null) updates['address'] = address;
    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _usersCollection.doc(uid).update(updates);
  }

  /// Mark email as verified
  static Future<void> markEmailVerified(String uid) async {
    await _usersCollection.doc(uid).update({
      'isEmailVerified': true,
      'emailVerifiedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add to favorites
  static Future<void> addToFavorites(String uid, String listingId) async {
    await _usersCollection.doc(uid).update({
      'favoriteIds': FieldValue.arrayUnion([listingId]),
    });
  }

  /// Remove from favorites
  static Future<void> removeFromFavorites(String uid, String listingId) async {
    await _usersCollection.doc(uid).update({
      'favoriteIds': FieldValue.arrayRemove([listingId]),
    });
  }

  /// Check if listing is favorited
  static Future<bool> isFavorite(String uid, String listingId) async {
    final user = await getUserDocument(uid);
    final favorites =
        (user?['favoriteIds'] as List<dynamic>?)?.cast<String>() ?? [];
    return favorites.contains(listingId);
  }

  /// Get favorite listings
  static Future<List<Map<String, dynamic>>> getFavoriteListings(
    String uid,
  ) async {
    final user = await getUserDocument(uid);
    final favorites =
        (user?['favoriteIds'] as List<dynamic>?)?.cast<String>() ?? [];

    if (favorites.isEmpty) return [];

    final futures = favorites.map((id) => _listingsCollection.doc(id).get());
    final snapshots = await Future.wait(futures);
    return snapshots
        .map((s) => s.data())
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Increment view count
  static Future<void> incrementViewCount(String listingId) async {
    // View counts are intentionally not client-controlled.
    return;
  }
}
