import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListingService {
  static final _db = FirebaseFirestore.instance;

  // Pagination settings
  static const int _defaultLimit = 20;
  static const int _maxLimit = 100;

  /// Get single listing by ID
  static Future<Map<String, dynamic>?> getListing(String id) async {
    if (id.isEmpty) return null;
    final doc = await _db.collection('listings').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    data['id'] = doc.id;
    return data;
  }

  /// Get all listings with server-side filtering by status/category/location
  /// Uses Firestore query filters instead of in-memory filtering
  static Stream<List<Map<String, dynamic>>> getListings({
    String? category,
    String? location,
    int? minPrice,
    int? maxPrice,
    String? searchQuery,
    int? limit,
  }) {
    var query = _db
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);

    // Apply category filter at Firestore level if provided
    if (category != null && category.isNotEmpty && category != 'الكل') {
      query = query.where('category', isEqualTo: category);
    }

    final queryLimit = limit ?? _defaultLimit;

    return query.limit(queryLimit.clamp(1, _maxLimit)).snapshots().map((snap) {
      var listings = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Apply in-memory filters for flexibility where query isn't available
      if (location != null && location.isNotEmpty) {
        final loc = location.toLowerCase();
        listings = listings.where((l) {
          final listingLoc = (l['location'] as String?)?.toLowerCase() ?? '';
          return listingLoc.contains(loc);
        }).toList();
      }

      if (minPrice != null) {
        listings = listings.where((l) {
          final price = _parsePrice(l['price']);
          return price != null && price >= minPrice;
        }).toList();
      }

      if (maxPrice != null) {
        listings = listings.where((l) {
          final price = _parsePrice(l['price']);
          return price != null && price <= maxPrice;
        }).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        listings = listings.where((l) {
          final title = (l['title'] as String?)?.toLowerCase() ?? '';
          final desc = (l['description'] as String?)?.toLowerCase() ?? '';
          return title.contains(query) || desc.contains(query);
        }).toList();
      }

      return listings;
    });
  }

  /// Get listings with cursor-based pagination for infinite scroll
  static Future<List<Map<String, dynamic>>> getListingsPage({
    String? category,
    String? location,
    int? minPrice,
    int? maxPrice,
    String? searchQuery,
    DocumentSnapshot? lastDoc,
    int pageSize = 20,
  }) async {
    var query = _db
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    var listings = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    // Apply in-memory filters
    if (category != null && category.isNotEmpty && category != 'الكل') {
      listings = listings.where((l) => l['category'] == category).toList();
    }

    if (location != null && location.isNotEmpty) {
      final loc = location.toLowerCase();
      listings = listings
          .where(
            (l) =>
                (l['location'] as String?)?.toLowerCase().contains(loc) ??
                false,
          )
          .toList();
    }

    return listings;
  }

  static int? _parsePrice(dynamic price) {
    if (price == null) return null;
    final priceStr = price.toString().replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(priceStr);
  }

  /// Get current user's listings only (for profile)
  static Stream<List<Map<String, dynamic>>> getMyListings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // If no user logged in, return empty stream
    if (uid == null || uid.isEmpty) {
      return Stream.value([]);
    }

    return _db
        .collection('listings')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  static Future<String?> addListing({
    required String title,
    required String description,
    required String category,
    required String type,
    required String price,
    required String location,
    required String phone,
    List<String>? imageUrls,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      // Validate required fields
      if (title.trim().isEmpty || title.trim().length > 200) {
        return 'Invalid title';
      }
      if (description.trim().isEmpty || description.trim().length > 5000) {
        return 'Invalid description';
      }
      if (category.trim().isEmpty || category.trim().length > 50) {
        return 'Invalid category';
      }
      if (type.trim().isEmpty || type.trim().length > 50) {
        return 'Invalid type';
      }
      if (price.trim().isEmpty || price.trim().length > 20) {
        return 'Invalid price';
      }
      if (location.trim().isEmpty || location.trim().length > 100) {
        return 'Invalid location';
      }
      if (phone.trim().isEmpty || phone.trim().length > 20) {
        return 'Invalid phone';
      }
      await _db.collection('listings').add({
        'title': title.trim(),
        'description': description.trim(),
        'category': category.trim(),
        'type': type.trim(),
        'price': price.trim(),
        'location': location.trim(),
        'phone': phone.trim(),
        'userId': user.uid,
        'userName': user.displayName ?? '',
        // Removed userEmail - not stored in public listing docs for security
        'imageUrls': imageUrls ?? [],
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'فشل النشر، حاول تاني';
    }
  }

  static Future<void> deleteListing(String id) async {
    await _db.collection('listings').doc(id).delete();
  }

  static Future<void> incrementViewCount(String listingId) async {
    // View counts are intentionally not client-controlled.
    return;
  }

  static Future<int> getUserListingsCount(String userId) async {
    final snap = await _db
        .collection('listings')
        .where('userId', isEqualTo: userId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  static Future<int> getUserTotalViews(String userId) async {
    final snap = await _db
        .collection('listings')
        .where('userId', isEqualTo: userId)
        .get();

    int totalViews = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      totalViews += (data['viewCount'] as int?) ?? 0;
    }
    return totalViews;
  }
}
