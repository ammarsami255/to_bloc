import 'package:flutter/material.dart';
import 'package:el_moza3/Constants.dart';
import 'package:el_moza3/services/listing_service.dart';
import 'package:el_moza3/widget/service_card.dart';
import 'package:el_moza3/screens/service_detail_screen.dart';
import 'package:el_moza3/screens/notifications_screen.dart';

class ServicesScreen extends StatefulWidget {
  final Future<void> Function() onRequireLogin;

  const ServicesScreen({super.key, required this.onRequireLogin});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  int _selectedCategory = 0;
  final _searchCtrl = TextEditingController();
  String? _filterLocation;
  int? _minPrice;
  int? _maxPrice;
  bool _showFilters = false;

  static const List<Map<String, dynamic>> _categories = [
    {"label": "الكل", "icon": Icons.apps},
    {"label": "خدمات مهنية", "icon": Icons.business_center},
    {"label": "صناعة وتصنيع", "icon": Icons.factory},
    {"label": "مقاولات", "icon": Icons.construction},
    {"label": "نقل ولوجستيات", "icon": Icons.local_shipping},
  ];

  static const Map<String, IconData> _categoryIcons = {
    "خدمات مهنية": Icons.business_center,
    "صناعة وتصنيع": Icons.factory,
    "مقاولات": Icons.construction,
    "نقل ولوجستيات": Icons.local_shipping,
  };

  static const Map<String, Color> _categoryColors = {
    "خدمات مهنية": Color(0xFF3B82F6),
    "صناعة وتصنيع": Color(0xFFF97316),
    "مقاولات": Color(0xFF22C55E),
    "نقل ولوجستيات": Color(0xFFEF4444),
  };

  // ignore: unused_field
  static const List<String> _locations = [
    "الكل",
    "القاهرة",
    "الجيزة",
    "الاسكندرية",
    "المنصورة",
    "طنطا",
    "بورسعيد",
    "السويس",
    "الاقصر",
    "اسوان",
  ];

  String get _selectedCategoryLabel =>
      _categories[_selectedCategory]["label"] as String;

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _filterLocation = null;
      _minPrice = null;
      _maxPrice = null;
      _showFilters = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 8),
            _buildCategories(),
            if (_showFilters) _buildFilterPanel(),
            const SizedBox(height: 8),
            Expanded(child: _buildListings()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppBorders.radiusMedium,
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "الموزّع",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "سوق الخدمات",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildNotificationBtn(),
        ],
      ),
    );
  }

  Widget _buildNotificationBtn() {
    return GestureDetector(
      onTap: _onNotificationTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorders.radiusMedium,
          boxShadow: AppShadows.small,
        ),
        child: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  void _onNotificationTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppBorders.radiusMedium,
                boxShadow: AppShadows.small,
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ابحث عن الخدمات...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _showFilters ? AppColors.primary : AppColors.surface,
              borderRadius: AppBorders.radiusMedium,
              boxShadow: AppShadows.small,
            ),
            child: IconButton(
              icon: Icon(
                Icons.tune,
                color: _showFilters ? Colors.white : AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorders.radiusMedium,
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الفلاتر',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(onPressed: _clearFilters, child: const Text('مسح')),
            ],
          ),
          const SizedBox(height: 12),
          // Location filter
          const Text(
            'الموقع',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('All', _filterLocation == null, () {
                  setState(() => _filterLocation = null);
                }),
                _filterChip('القاهرة', _filterLocation == 'القاهرة', () {
                  setState(() => _filterLocation = 'القاهرة');
                }),
                _filterChip('الجيزة', _filterLocation == 'الجيزة', () {
                  setState(() => _filterLocation = 'الجيزة');
                }),
                _filterChip('الاسكندرية', _filterLocation == 'الاسكندرية', () {
                  setState(() => _filterLocation = 'الاسكندرية');
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Price range
          const Text(
            'السعر (ج.م)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'من',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    isDense: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: AppBorders.radiusSmall,
                    ),
                  ),
                  onChanged: (v) => _minPrice = int.tryParse(v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'إلى',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    isDense: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: AppBorders.radiusSmall,
                    ),
                  ),
                  onChanged: (v) => _maxPrice = int.tryParse(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: selected ? null : AppShadows.small,
              ),
              child: Row(
                children: [
                  Icon(
                    _categories[index]["icon"] as IconData,
                    size: 18,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _categories[index]["label"] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListings() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ListingService.getListings(
        category: _selectedCategoryLabel == 'الكل'
            ? null
            : _selectedCategoryLabel,
        location: _filterLocation,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        searchQuery: _searchCtrl.text.trim().isEmpty
            ? null
            : _searchCtrl.text.trim(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final listings = snapshot.data ?? [];

        if (listings.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${listings.length} إعلانات",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: listings.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final item = listings[index];
                  final cat = item["category"] as String? ?? "";
                  return ServiceCard(
                    title: item["title"] ?? "",
                    category: cat,
                    price: item["price"] ?? "",
                    location: item["location"] ?? "",
                    icon: _categoryIcons[cat] ?? Icons.miscellaneous_services,
                    color: _categoryColors[cat] ?? AppColors.primary,
                    type: item["type"] ?? "",
                    onTap: () {
                      // Show listing detail - public access allowed
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceDetailScreen(
                            item: item,
                            onRequireLogin: widget.onRequireLogin,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "مفيش إعلانات",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "جرب تفلتر نتائجك",
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
