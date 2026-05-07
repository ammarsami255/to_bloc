/// Listing model for B2B marketplace services/products
class ListingModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String type;
  final String price;
  final String location;
  final String phone;
  final String userId;
  final String userName;
  final String? userPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int viewCount;
  final bool isActive;

  const ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.price,
    required this.location,
    required this.phone,
    required this.userId,
    required this.userName,
    this.userPhone,
    this.createdAt,
    this.updatedAt,
    this.viewCount = 0,
    this.isActive = true,
  });

  factory ListingModel.fromMap(String id, Map<String, dynamic> data) {
    return ListingModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      type: data['type'] ?? '',
      price: data['price'] ?? '',
      location: data['location'] ?? '',
      phone: data['phone'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'],
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
      viewCount: data['viewCount'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      'price': price,
      'location': location,
      'phone': phone,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'viewCount': viewCount,
      'isActive': isActive,
    };
  }

  ListingModel copyWith({
    String? title,
    String? description,
    String? category,
    String? type,
    String? price,
    String? location,
    String? phone,
    String? userName,
    String? userPhone,
    int? viewCount,
    bool? isActive,
  }) {
    return ListingModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      price: price ?? this.price,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      userId: userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      createdAt: createdAt,
      updatedAt: updatedAt,
      viewCount: viewCount ?? this.viewCount,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Category constants
class ListingCategory {
  static const String all = 'الكل';
  static const String professionalServices = 'خدمات مهنية';
  static const String manufacturing = 'صناعة وتصنيع';
  static const String contracting = 'مقاولات';
  static const String logistics = 'نقل ولوجستيات';

  static const List<String> categories = [
    all,
    professionalServices,
    manufacturing,
    contracting,
    logistics,
  ];

  static const Map<String, String> categoryIcons = {
    professionalServices: 'business_center',
    manufacturing: 'factory',
    contracting: 'construction',
    logistics: 'local_shipping',
  };
}

/// Type constants
class ListingType {
  static const String service = 'Service';
  static const String product = 'Product';
  static const String request = 'Request';

  static const List<String> types = [service, product, request];
}
