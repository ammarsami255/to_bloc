import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_moza3/Constants.dart';
import 'package:el_moza3/services/auth_service.dart';
import 'package:el_moza3/services/chat_service.dart';
import 'package:el_moza3/screens/chat_screen.dart';
import 'package:el_moza3/screens/service_detail_screen.dart';

/// Screen showing user's notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background2,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'الإشعارات',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          if (userId != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.textSecondary,
              ),
              onPressed: () => _showClearDialog(userId),
            ),
        ],
      ),
      body: userId == null
          ? _buildNotLoggedIn()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(userId)
                  .collection('items')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildError();
                }

                final notifications = snapshot.data?.docs ?? [];

                if (notifications.isEmpty) {
                  return _buildEmpty();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final dataMap = doc.data() as Map<String, dynamic>? ?? {};
                    return _NotificationTile(
                      title: dataMap['title'] as String? ?? '',
                      body: dataMap['body'] as String? ?? '',
                      type: dataMap['type'] as String? ?? 'info',
                      createdAt: dataMap['createdAt'] as Timestamp?,
                      read: dataMap['read'] as bool? ?? false,
                      onTap: () => _handleTap(doc.id, dataMap),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmpty() {
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
              Icons.notifications_none_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll see updates here',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.login_rounded,
            size: 60,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Login to see notifications',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 60, color: AppColors.error),
          SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _handleTap(String notificationId, Map<String, dynamic> dataMap) async {
    final userId = AuthService.currentUser?.uid;
    if (userId == null) return;

    final read = dataMap['read'] as bool? ?? false;
    if (!read) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc(notificationId)
          .update({'read': true});
    }

    final type = dataMap['type'] as String?;
    final actionData = dataMap['actionData'] as Map<String, dynamic>?;

    if (type == 'chat' && actionData != null) {
      final chatId = actionData['chatId'] as String?;
      if (chatId != null && context.mounted) {
        final participants = await ChatService.getParticipants(chatId);
        if (!participants.contains(userId)) return;

        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );
        if (otherUserId.isEmpty || !context.mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatDetailScreen(chatId: chatId, otherUserId: otherUserId),
          ),
        );
      }
    } else if (type == 'listing' && actionData != null) {
      final listingId = actionData['listingId'] as String?;
      if (listingId != null && context.mounted) {
        final doc = await FirebaseFirestore.instance
            .collection('listings')
            .doc(listingId)
            .get();
        final item = doc.data();
        if (!doc.exists || item == null || !context.mounted) return;

        item['id'] = doc.id;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ServiceDetailScreen(item: item, onRequireLogin: () async {}),
          ),
        );
      }
    }
  }

  void _showClearDialog(String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearNotifications(userId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearNotifications(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear notifications')),
        );
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String type;
  final Timestamp? createdAt;
  final bool read;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.read,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getIcon();
    final iconColor = _getColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: read
              ? AppColors.surface
              : AppColors.primaryLighter.withOpacity(0.3),
          borderRadius: AppBorders.radiusMedium,
          border: read
              ? null
              : Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: AppBorders.radiusSmall,
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: read ? FontWeight.normal : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(createdAt!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!read)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'listing':
        return Icons.miscellaneous_services;
      case 'offer':
        return Icons.local_offer_outlined;
      case 'system':
        return Icons.info_outline_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColor() {
    switch (type) {
      case 'chat':
        return AppColors.primary;
      case 'listing':
        return Colors.green;
      case 'offer':
        return Colors.orange;
      case 'system':
        return Colors.blue;
      case 'warning':
        return Colors.amber;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final dt = timestamp.toDate();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
