import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat model for Firestore
class ChatModel {
  final String id;
  final List<String> participants;
  final String? listingId;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime? createdAt;
  final Map<String, bool> typing;
  final Map<String, DateTime> lastSeen;
  final Map<String, int> unreadCount;

  ChatModel({
    required this.id,
    required this.participants,
    this.listingId,
    this.lastMessage,
    this.lastMessageTime,
    this.createdAt,
    this.typing = const {},
    this.lastSeen = const {},
    this.unreadCount = const {},
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return ChatModel(
      id: doc.id,
      participants:
          (data?['participants'] as List<dynamic>?)?.cast<String>() ?? [],
      listingId: data?['listingId'] as String?,
      lastMessage: data?['lastMessage'] as String?,
      lastMessageTime: data?['lastMessageTime'] != null
          ? (data!['lastMessageTime'] as Timestamp).toDate()
          : null,
      createdAt: data?['createdAt'] != null
          ? (data!['createdAt'] as Timestamp).toDate()
          : null,
      typing:
          (data?['typing'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v as bool),
          ) ??
          {},
      lastSeen:
          (data?['lastSeen'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), (v as Timestamp).toDate()),
          ) ??
          {},
      unreadCount:
          (data?['unreadCount'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      if (listingId != null) 'listingId': listingId,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageTime != null) 'lastMessageTime': lastMessageTime,
      if (createdAt != null) 'createdAt': createdAt,
      'typing': typing,
      'lastSeen': lastSeen,
      'unreadCount': unreadCount,
    };
  }

  /// Get the other participant's ID (not current user)
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (uid) => uid != currentUserId,
      orElse: () => participants.first,
    );
  }

  /// Check if user is participant
  bool isParticipant(String uid) => participants.contains(uid);
}

/// Message model for Firestore
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final MessageType type;
  final bool isSeen;
  final DateTime? seenAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.type = MessageType.text,
    this.isSeen = false,
    this.seenAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return MessageModel(
      id: doc.id,
      chatId: data?['chatId'] as String? ?? '',
      senderId: data?['senderId'] as String? ?? '',
      content: data?['content'] as String? ?? '',
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (t) => t.name == (data?['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      isSeen: (data?['isSeen'] as bool?) ?? ((data?['seenBy'] as List?)?.isNotEmpty ?? false),
      seenAt: (data?['seenAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'createdAt': createdAt,
      'type': type.name,
      'isSeen': isSeen,
      if (seenAt != null) 'seenAt': seenAt,
    };
  }
}

enum MessageType { text, image }

extension MessageTypeExtension on MessageType {
  String get name {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
    }
  }
}
