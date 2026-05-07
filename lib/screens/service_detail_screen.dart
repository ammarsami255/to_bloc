import 'package:flutter/material.dart';
import 'package:el_moza3/Constants.dart';
import 'package:el_moza3/services/auth_service.dart';
import 'package:el_moza3/services/chat_service.dart';
import 'package:el_moza3/services/database_service.dart';
import 'package:el_moza3/utils/whatsapp_helper.dart';
import 'package:el_moza3/screens/chat_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final Future<void> Function() onRequireLogin;

  const ServiceDetailScreen({
    super.key,
    required this.item,
    required this.onRequireLogin,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  bool _isSaved = false;
  bool _isLoadingSave = false;
  bool _isLoadingChat = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _currentUserId = AuthService.currentUser?.uid;
  }

  Future<void> _checkIfSaved() async {
    final user = AuthService.currentUser;
    if (user != null) {
      final listingId = widget.item['id'] as String?;
      if (listingId != null) {
        final isFav = await DatabaseService.isFavorite(user.uid, listingId);
        if (mounted) {
          setState(() => _isSaved = isFav);
        }
      }
    }
  }

  Future<void> _toggleSave() async {
    final user = AuthService.currentUser;
    if (user == null) {
      await widget.onRequireLogin();
      return;
    }

    final listingId = widget.item['id'] as String?;
    if (listingId == null) return;

    setState(() => _isLoadingSave = true);

    try {
      if (_isSaved) {
        await DatabaseService.removeFromFavorites(user.uid, listingId);
      } else {
        await DatabaseService.addToFavorites(user.uid, listingId);
      }
      if (mounted) {
        setState(() => _isSaved = !_isSaved);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSave = false);
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.item['phone'] as String?;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رقم الهاتف غير متوفر'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await WhatsAppHelper.openWhatsAppWithFallback(
      phone,
      onError: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.error),
          );
        }
      },
    );
  }

  Future<void> _openInAppChat() async {
    final user = AuthService.currentUser;
    if (user == null) {
      await widget.onRequireLogin();
      return;
    }

    final sellerId = widget.item['userId'] as String?;
    if (sellerId == null || sellerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح المحادثة'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (sellerId == user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكنك مراسلة نفسك'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isLoadingChat = true);

    try {
      final chatId = await ChatService.getOrCreateChat(
        sellerId,
        listingId: widget.item['id'] as String?,
        otherUserName: widget.item['userName'] as String?,
      );
      if (chatId != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatDetailScreen(chatId: chatId, otherUserId: sellerId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح المحادثة'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingChat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.item["type"] as String? ?? "";
    final title = widget.item["title"] as String? ?? "";
    final description = widget.item["description"] as String? ?? "";
    final price = widget.item["price"] as String? ?? "";
    final location = widget.item["location"] as String? ?? "";
    final phone = widget.item["phone"] as String? ?? "";
    final userName = widget.item["userName"] as String? ?? "";
    final category = widget.item["category"] as String? ?? "";
    final isRequest = (type == "طلب خدمة") || (type == "Looking for Service");
    final displayType = isRequest ? "طلب خدمة" : "عرض خدمة";
    final displayColor = isRequest ? Colors.orange : Colors.green;
    final listingId = widget.item['id'] as String?;
    final isOwnListing =
        _currentUserId != null &&
        (widget.item['userId'] as String?) == _currentUserId;

    return Scaffold(
      backgroundColor: AppColors.background2,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppBorders.radiusMedium,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isOwnListing && listingId != null)
                    GestureDetector(
                      onTap: _isLoadingSave ? null : _toggleSave,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isSaved
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.surface,
                          borderRadius: AppBorders.radiusMedium,
                        ),
                        child: _isLoadingSave
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Icon(
                                _isSaved
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isSaved
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: displayColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      displayType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: displayColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? "عنوان غير محدد" : title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLighter,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.isEmpty ? "تصنيف غير محدد" : category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            location.isEmpty ? "غير محدد" : location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppBorders.radiusMedium,
                        boxShadow: AppShadows.small,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "السعر",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            price.isEmpty ? "غير محدد" : "$price ج.م",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppBorders.radiusMedium,
                        boxShadow: AppShadows.small,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "الوصف",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description.isEmpty ? "لا يوجد وصف" : description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppBorders.radiusMedium,
                        boxShadow: AppShadows.small,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLighter,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "البائع",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userName.isEmpty
                                      ? "مستخدم غير معروف"
                                      : userName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: phone.isNotEmpty
                                  ? _openWhatsApp
                                  : null,
                              icon: const Icon(
                                Icons.contact_phone,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'واتساب',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppBorders.radiusMedium,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingChat ? null : _openInAppChat,
                              icon: _isLoadingChat
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: Colors.white,
                                    ),
                              label: const Text(
                                'مراسلة',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppBorders.radiusMedium,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
