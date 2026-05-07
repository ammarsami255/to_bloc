import 'package:flutter/material.dart';
import 'package:el_moza3/Constants.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final String category;
  final String price;
  final String location;
  final IconData icon;
  final Color color;
  final String type;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.title,
    required this.category,
    required this.price,
    required this.location,
    required this.icon,
    required this.color,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRequest = (type == "طلب خدمة") || (type == "Looking for Service");
    final displayType = isRequest ? "طلب" : "عرض";
    final displayColor = isRequest ? Colors.orange : Colors.green;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorders.radiusMedium,
          boxShadow: AppShadows.small,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Type row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: AppBorders.radiusSmall,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: displayColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        displayType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: displayColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Title - fixed overflow
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  title.isEmpty ? "عنوان غير محدد" : title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              // Category
              Text(
                category.isEmpty ? "تصنيف غير محدد" : category,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const SizedBox(height: 6),
              // Price and Location row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      price.isEmpty ? "سعر غير محدد" : "$price ج.م",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      location.isEmpty ? "موقع غير محدد" : location,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
