import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:el_moza3/models/chat_model.dart';

class ChatService {
  ChatService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static CollectionReference<Map<String, dynamic>> get _chatsCollection =>
      _firestore.collection('chats');

  static CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  static String? get _currentUserId => _auth.currentUser?.uid;

  // ==================== CHAT MANAGEMENT ====================

  static Future<String?> getOrCreateChat(
    String otherUserId, {
    String? listingId,
    String? otherUserName,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null || otherUserId.isEmpty) return null;

    final participants = [currentUserId, otherUserId]..sort();
    final chatId = '${participants[0]}_${participants[1]}';

    try {
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (chatDoc.exists) {
        final existingParticipants =
            (chatDoc.data()?['participants'] as List<dynamic>?)
                ?.cast<String>() ??
            [];
        if (existingParticipants.contains(currentUserId) &&
            existingParticipants.contains(otherUserId)) {
          return chatId;
        }
      }
    } catch (e) {
      // Ignored
    }

    try {
      await _chatsCollection.doc(chatId).set({
        'participants': participants,
        'participantNames': {
          currentUserId:
              _auth.currentUser?.displayName ??
              _auth.currentUser?.email?.split('@').first ??
              'User',
          otherUserId: otherUserName ?? 'User',
        },
        if (listingId != null) 'listingId': listingId,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'typing': {},
        'lastSeen': {},
        'unreadCount_$currentUserId': 0,
        'unreadCount_$otherUserId': 0,
      });
    } catch (e) {
      try {
        final chatDoc = await _chatsCollection.doc(chatId).get();
        if (chatDoc.exists) return chatId;
      } catch (e) {
        return null;
      }
    }

    return chatId;
  }

  static Future<ChatModel?> getChat(String chatId) async {
    final doc = await _chatsCollection.doc(chatId).get();
    if (!doc.exists) return null;
    return ChatModel.fromFirestore(doc);
  }

  static Future<void> deleteChat(String chatId) async {
    final messages = await _chatsCollection
        .doc(chatId)
        .collection('messages')
        .get();
    final batch = _firestore.batch();
    for (final msg in messages.docs) {
      batch.delete(msg.reference);
    }
    batch.delete(_chatsCollection.doc(chatId));
    await batch.commit();
  }

  // ==================== STREAMS ====================

  static Stream<List<Map<String, dynamic>>> getMyChats() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _chatsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        
        final unreadField = data['unreadCount_$userId'];
        final unreadMap = data['unreadCount'] as Map<dynamic, dynamic>?;

        if (unreadField != null) {
          data['unreadCount'] = (unreadField as num).toInt();
        } else if (unreadMap != null && unreadMap[userId] != null) {
          data['unreadCount'] = (unreadMap[userId] as num).toInt();
        } else {
          data['unreadCount'] = 0; // Optimistic default
          // Fire and forget migration
          _chatsCollection
              .doc(doc.id)
              .collection('messages')
              .where('senderId', isNotEqualTo: userId)
              .where('isSeen', isEqualTo: false)
              .get()
              .then((unreadMsgs) {
            doc.reference.update({'unreadCount_$userId': unreadMsgs.docs.length}).catchError((_) {});
          }).catchError((_) {});
        }
        return data;
      }).toList();
    });
  }

  static Stream<List<Map<String, dynamic>>> getMessages(
    String chatId, {
    int limit = 50,
  }) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            
            // Support old seenBy array for backward compatibility
            if (data['isSeen'] == null) {
              final seenBy = data['seenBy'] as List<dynamic>? ?? [];
              data['isSeen'] = seenBy.isNotEmpty;
            }
            
            return data;
          }).toList(),
        );
  }

  // ==================== SEND MESSAGES ====================

  static Future<String?> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final userId = _currentUserId;
    if (userId == null || content.trim().isEmpty) return null;

    final chatDoc = await _chatsCollection.doc(chatId).get();
    if (!chatDoc.exists) return null;

    final participants =
        (chatDoc.data()?['participants'] as List<dynamic>?)?.cast<String>() ??
        [];
    if (!participants.contains(userId)) return null;

    final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
    if (otherUserId.isEmpty) return null;

    String? messageId;

    await _firestore.runTransaction((transaction) async {
      final chat = await transaction.get(_chatsCollection.doc(chatId));
      if (!chat.exists) return;

      final messageRef = _chatsCollection
          .doc(chatId)
          .collection('messages')
          .doc();
          
      transaction.set(messageRef, {
        'chatId': chatId,
        'senderId': userId,
        'content': content.trim(),
        'type': type.name,
        'createdAt': FieldValue.serverTimestamp(),
        'isSeen': false,
        'seenAt': null,
      });
      messageId = messageRef.id;

      transaction.update(_chatsCollection.doc(chatId), {
        'lastMessage': content.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount_$otherUserId': FieldValue.increment(1),
      });
    });

    return messageId;
  }

  static Future<String?> sendImageMessage({
    required String chatId,
    required String imageUrl,
  }) async {
    return sendMessage(
      chatId: chatId,
      content: imageUrl,
      type: MessageType.image,
    );
  }

  // ==================== SEEN SYSTEM ====================

  static Future<void> resetUnreadCount(String chatId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _chatsCollection.doc(chatId).update({
      'unreadCount_$userId': 0,
      'lastSeen.$userId': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markMessagesAsSeen(String chatId, List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    
    final batch = _firestore.batch();
    
    for (final msgId in messageIds) {
      batch.update(_chatsCollection.doc(chatId).collection('messages').doc(msgId), {
        'isSeen': true,
        'seenAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ==================== PRESENCE (Realtime DB) ====================

  static Future<void> setOnline() async {
    initializePresence();
  }

  static void initializePresence() {
    final userId = _currentUserId;
    if (userId == null) return;

    final connectedRef = _database.ref('.info/connected');
    final userStatusRef = _database.ref('status/$userId');

    connectedRef.onValue.listen((event) {
      if (event.snapshot.value == true) {
        userStatusRef.onDisconnect().set({
          'online': false,
          'lastSeen': ServerValue.timestamp,
        }).then((_) {
          userStatusRef.set({
            'online': true,
            'lastSeen': ServerValue.timestamp,
          });
          
          _usersCollection.doc(userId).update({
            'online': true,
            'lastSeen': FieldValue.serverTimestamp(),
          }).catchError((_) {});
        });
      }
    });
  }

  static Future<void> setOffline() async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _database.ref('status/$userId').set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
    
    await _usersCollection.doc(userId).update({
      'online': false,
      'lastSeen': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  static Stream<Map<String, dynamic>> getUserPresenceStream(String userId) {
    return _database.ref('status/$userId').onValue.map((event) {
      if (event.snapshot.value == null) return {'online': false, 'lastSeen': null};
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return {
        'online': data['online'] == true,
        'lastSeen': data['lastSeen'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(data['lastSeen'] as int) 
            : null,
      };
    });
  }

  static Future<Map<String, dynamic>?> getChatWithParticipantDetails(
    String chatId,
  ) async {
    final doc = await _chatsCollection.doc(chatId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // ==================== TYPING INDICATOR ====================

  static Future<void> setTyping(String chatId, bool isTyping) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _chatsCollection.doc(chatId).update({'typing.$userId': isTyping});
  }

  static Stream<Map<String, bool>> getTypingStatus(String chatId) {
    return _chatsCollection.doc(chatId).snapshots().map((doc) {
      final data = doc.data() ?? {};
      final typing =
          (data['typing'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v as bool),
          ) ??
          {};
      return Map<String, bool>.from(typing);
    });
  }

  // ==================== CHAT BADGE ====================

  static Stream<int> getUnreadCountStream() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(0);

    return _chatsCollection
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final unreadField = data['unreadCount_$userId'];
            final unreadMap = data['unreadCount'] as Map<dynamic, dynamic>?;
            
            if (unreadField != null) {
              total += (unreadField as num).toInt();
            } else if (unreadMap != null && unreadMap[userId] != null) {
              total += (unreadMap[userId] as num).toInt();
            } else {
              _chatsCollection
                  .doc(doc.id)
                  .collection('messages')
                  .where('senderId', isNotEqualTo: userId)
                  .where('isSeen', isEqualTo: false)
                  .get()
                  .then((unreadMsgs) {
                doc.reference.update({'unreadCount_$userId': unreadMsgs.docs.length}).catchError((_) {});
              }).catchError((_) {});
            }
          }
          return total;
        });
  }

  static Stream<int> getUnreadChatsStream() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(0);

    return _chatsCollection
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int count = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final unreadField = data['unreadCount_$userId'];
            final unreadMap = data['unreadCount'] as Map<dynamic, dynamic>?;
            
            int unread = 0;
            if (unreadField != null) {
              unread = (unreadField as num).toInt();
            } else if (unreadMap != null && unreadMap[userId] != null) {
              unread = (unreadMap[userId] as num).toInt();
            } else {
              _chatsCollection
                  .doc(doc.id)
                  .collection('messages')
                  .where('senderId', isNotEqualTo: userId)
                  .where('isSeen', isEqualTo: false)
                  .get()
                  .then((unreadMsgs) {
                doc.reference.update({'unreadCount_$userId': unreadMsgs.docs.length}).catchError((_) {});
              }).catchError((_) {});
            }
            if (unread > 0) count++;
          }
          return count;
        });
  }

  static Future<List<String>> getParticipants(String chatId) async {
    final doc = await _chatsCollection.doc(chatId).get();
    return (doc.data()?['participants'] as List<dynamic>?)?.cast<String>() ?? [];
  }
}
