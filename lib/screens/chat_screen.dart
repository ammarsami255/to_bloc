import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_moza3/Constants.dart';
import 'package:el_moza3/services/chat_service.dart';
import 'package:el_moza3/services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Stream<List<Map<String, dynamic>>> _chatsStream;

  @override
  void initState() {
    super.initState();
    _chatsStream = ChatService.getMyChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppBorders.radiusMedium,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error);
                  }

                  final chats = snapshot.data ?? [];

                  if (chats.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: chats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return _ChatTile(chat: chat);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a conversation by contacting a seller',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please try again',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> chat;

  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final participants = (chat['participants'] as List<dynamic>).cast<String>();
    final currentUserId = AuthService.currentUser?.uid ?? '';
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    final lastMessage = chat['lastMessage'] ?? '';
    final lastTime = chat['lastMessageTime'] as Timestamp?;

    final participantNames =
        (chat['participantNames'] as Map<dynamic, dynamic>?)?.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ) ??
        {};
    final userName = participantNames[otherUserId] ?? 'User';

    String? profileImage;
    final otherUserData = chat['participantProfiles'] as Map<dynamic, dynamic>?;
    if (otherUserData != null) {
      profileImage = otherUserData[otherUserId] as String?;
    }

    final unreadCount = chat['unreadCount'] as int? ?? 0;

    return _ChatTileUI(
      userName: userName,
      lastMessage: lastMessage,
      lastTime: lastTime,
      chatId: chat['id'],
      otherUserId: otherUserId,
      profileImage: profileImage,
      unreadCount: unreadCount,
    );
  }
}

class _ChatTileUI extends StatelessWidget {
  final String userName;
  final String lastMessage;
  final Timestamp? lastTime;
  final String chatId;
  final String otherUserId;
  final String? profileImage;
  final int unreadCount;

  const _ChatTileUI({
    required this.userName,
    required this.lastMessage,
    required this.lastTime,
    required this.chatId,
    required this.otherUserId,
    this.profileImage,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatDetailScreen(chatId: chatId, otherUserId: otherUserId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorders.radiusMedium,
          boxShadow: AppShadows.small,
        ),
        child: Row(
          children: [
            _ChatAvatar(imageUrl: profileImage, name: userName, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(lastTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: unreadCount > 0
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.isEmpty
                        ? 'Start a conversation...'
                        : lastMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: lastMessage.isEmpty
                          ? AppColors.textHint
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final time = timestamp.toDate();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.day}/${time.month}';
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  String _otherUserName = 'User';
  String? _otherUserProfileImage;
  bool _isLoading = true;

  bool _isOtherUserOnline = false;
  DateTime? _otherUserLastSeen;
  StreamSubscription? _presenceSub;
  late Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = ChatService.getMessages(widget.chatId);
    _loadParticipantDetails();
    _setupPresenceListener();
    ChatService.resetUnreadCount(widget.chatId);
  }

  void _setupPresenceListener() {
    _presenceSub = ChatService.getUserPresenceStream(widget.otherUserId)
        .listen((presence) {
      if (mounted) {
        setState(() {
          _isOtherUserOnline = presence['online'] ?? false;
          _otherUserLastSeen = presence['lastSeen'];
        });
      }
    });
  }

  Future<void> _loadParticipantDetails() async {
    try {
      final chatData = await ChatService.getChatWithParticipantDetails(
        widget.chatId,
      );
      if (chatData != null) {
        final participantNames =
            chatData['participantNames'] as Map<dynamic, dynamic>? ?? {};
        _otherUserName =
            participantNames[widget.otherUserId] as String? ?? 'User';

        final participantProfiles =
            chatData['participantProfiles'] as Map<dynamic, dynamic>? ?? {};
        _otherUserProfileImage =
            participantProfiles[widget.otherUserId] as String?;
      }
    } catch (e) {
      // Keep defaults
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _presenceSub?.cancel();
    super.dispose();
  }

  String _getLastSeenText() {
    if (_otherUserLastSeen == null) return 'offline';
    final now = DateTime.now();
    final diff = now.difference(_otherUserLastSeen!);

    if (diff.inMinutes < 1) {
      return 'last seen just now';
    } else if (diff.inMinutes < 60) {
      return 'last seen ${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return 'last seen ${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'last seen yesterday';
    } else {
      return 'last seen ${diff.inDays}d ago';
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageCtrl.text.trim();
    if (content.isEmpty || _sending) return;

    setState(() => _sending = true);
    _messageCtrl.clear();

    try {
      await ChatService.sendMessage(chatId: widget.chatId, content: content);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: _isLoading
            ? const Text('Chat', style: TextStyle(color: AppColors.textPrimary))
            : Row(
                children: [
                  _ChatAvatar(
                    imageUrl: _otherUserProfileImage,
                    name: _otherUserName,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _otherUserName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _isOtherUserOnline ? 'online' : _getLastSeenText(),
                          style: TextStyle(
                            color: _isOtherUserOnline
                                ? Colors.green
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                
                final currentUserId = AuthService.currentUser?.uid;
                final unreadMessageIds = messages
                    .where((m) => m['senderId'] != currentUserId && m['isSeen'] == false)
                    .map((m) => m['id'] as String)
                    .toList();

                if (unreadMessageIds.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ChatService.markMessagesAsSeen(widget.chatId, unreadMessageIds);
                    }
                  });
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  reverse: true, // Display latest at bottom effectively
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe =
                        message['senderId'] == AuthService.currentUser?.uid;
                    return _MessageBubble(
                      content: message['content'] ?? '',
                      isMe: isMe,
                      createdAt: message['createdAt'] as Timestamp?,
                      isSeen: message['isSeen'] ?? false,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.background2,
                borderRadius: AppBorders.radiusMedium,
              ),
              child: TextField(
                controller: _messageCtrl,
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppBorders.radiusMedium,
            ),
            child: IconButton(
              onPressed: _sending ? null : _sendMessage,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final Timestamp? createdAt;
  final bool isSeen;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    this.createdAt,
    this.isSeen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildSeenIcon(isSeen),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final time = timestamp.toDate();
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSeenIcon(bool seen) {
    if (seen) {
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: Colors.lightBlueAccent,
      );
    } else {
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: Colors.white70,
      );
    }
  }
}

class _ChatAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;

  const _ChatAvatar({this.imageUrl, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final initials = _getInitials(name);
    final Color bgColor = _getColorFromName(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getColorFromName(String name) {
    final colors = [
      AppColors.primary,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[index];
  }
}
