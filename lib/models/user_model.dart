import 'package:firebase_auth/firebase_auth.dart';

/// User model with data from Firestore
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final String? profileImageUrl;
  final String? companyName;
  final String? address;
  final List<String>? favoriteIds;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.isEmailVerified = false,
    this.createdAt,
    this.profileImageUrl,
    this.companyName,
    this.address,
    this.favoriteIds,
  });

  factory UserModel.fromFirebaseUser(User user, {Map<String, dynamic>? data}) {
    return UserModel(
      uid: user.uid,
      name: user.displayName ?? user.email?.split('@').first ?? '',
      email: user.email ?? '',
      isEmailVerified: data?['isEmailVerified'] ?? false,
      phone: data?['phone'],
      createdAt: data?['createdAt']?.toDate(),
      profileImageUrl: data?['profileImageUrl'],
      companyName: data?['companyName'],
      address: data?['address'],
      favoriteIds: (data?['favoriteIds'] as List<dynamic>?)?.cast<String>(),
    );
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: data['createdAt']?.toDate(),
      profileImageUrl: data['profileImageUrl'],
      companyName: data['companyName'],
      address: data['address'],
      favoriteIds: (data['favoriteIds'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt,
      'profileImageUrl': profileImageUrl,
      'companyName': companyName,
      'address': address,
      'favoriteIds': favoriteIds,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    bool? isEmailVerified,
    String? profileImageUrl,
    String? companyName,
    String? address,
    List<String>? favoriteIds,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}
