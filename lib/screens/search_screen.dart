import 'package:flutter/material.dart';
import 'package:el_moza3/Constants.dart';
import 'package:el_moza3/services/listing_service.dart';
import 'package:el_moza3/widget/service_card.dart';
import 'package:el_moza3/screens/service_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final Future<void> Function() onRequireLogin;

  const SearchScreen({super.key, required this.onRequireLogin});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = "";
  List<Map<String, dynamic>> _all = [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const Map<String, IconData> _icons = {
    "خدمات مهنية": Icons.business_center,
    "صناعة وتصنيع": Icons.factory,
    "مقاولات": Icons.construction,
    "نقل ولوجستيات": Icons.local_shipping,
  };

  static const Map<String, Color> _colors = {
    "خدمات مهنية": Colors.blue,
    "صناعة وتصنيع": Colors.orange,
    "مقاولات": Colors.green,
    "نقل ولوجستيات": Colors.red,
  };

  List<Map<String, dynamic>> get _results {
    if (_query.isEmpty) return [];
    return _all
        .where(
          (e) =>
              (e["title"] as String? ?? "").contains(_query) ||
              (e["category"] as String? ?? "").contains(_query) ||
              (e["location"] as String? ?? "").contains(_query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ListingService.getListings(),
      builder: (context, snap) {
        _all = snap.data ?? [];
        return Scaffold(
          backgroundColor: AppColors.background2,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "بحث",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _ctrl,
                    textAlign: TextAlign.right,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: "ابحث عن خدمة، موقع، تصنيف...",
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _ctrl.clear();
                                setState(() => _query = "");
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadius,
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadius,
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadius,
                        ),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_query.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 60,
                              color: AppColors.border,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "ابحث عن أي خدمة",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_results.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 60,
                              color: AppColors.border,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "مفيش نتائج",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final cat = item["category"] as String? ?? "";
                          return ServiceCard(
                            title: item["title"] ?? "",
                            category: cat,
                            price: item["price"] ?? "",
                            location: item["location"] ?? "",
                            icon: _icons[cat] ?? Icons.miscellaneous_services,
                            color: _colors[cat] ?? AppColors.primary,
                            type: item["type"] ?? "",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceDetailScreen(
                                  item: item,
                                  onRequireLogin: widget.onRequireLogin,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
