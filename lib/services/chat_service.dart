import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trash_dash_demo/models/chat_models.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get or create a conversation between two users about an item
  static Future<ChatConversation> getOrCreateConversation({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
    String? itemId,
    String? itemName,
  }) async {
    // Check if conversation already exists between these users for this item
    final existingQuery = await _firestore
        .collection('chats')
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (var doc in existingQuery.docs) {
      final data = doc.data();
      final participants = List<String>.from(data['participantIds'] ?? []);
      final docItemId = data['itemId'];

      // Check if this conversation is between the same users and for the same item
      if (participants.contains(otherUserId) &&
          (itemId == null || docItemId == itemId)) {
        return ChatConversation.fromFirestore(doc);
      }
    }

    // Create new conversation
    final conversationRef = _firestore.collection('chats').doc();
    final conversation = ChatConversation(
      id: conversationRef.id,
      participantIds: [currentUserId, otherUserId],
      participantNames: {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      itemId: itemId,
      itemName: itemName,
      unreadStatus: {
        currentUserId: false,
        otherUserId: false,
      },
      createdAt: DateTime.now(),
    );

    await conversationRef.set(conversation.toFirestore());
    return conversation;
  }

  /// Get all conversations for a user - simplified query without orderBy
  static Stream<List<ChatConversation>> getUserConversations(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => ChatConversation.fromFirestore(doc))
          .toList();

      // Sort in memory instead of using orderBy (avoids composite index)
      conversations.sort((a, b) {
        final aTime = a.lastMessageTimestamp ?? a.createdAt;
        final bTime = b.lastMessageTimestamp ?? b.createdAt;
        return bTime.compareTo(aTime); // Descending
      });

      return conversations;
    });
  }

  /// Get messages for a conversation
  static Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  /// Send a message
  static Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    required String recipientId,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final message = ChatMessage(
      id: messageRef.id,
      senderId: senderId,
      senderName: senderName,
      content: content,
      sentAt: DateTime.now(),
      isRead: false,
    );

    final batch = _firestore.batch();

    batch.set(messageRef, message.toFirestore());

    final conversationRef = _firestore.collection('chats').doc(conversationId);
    batch.update(conversationRef, {
      'lastMessage': content,
      'lastMessageTimestamp': Timestamp.fromDate(DateTime.now()),
      'lastMessageSenderId': senderId,
      'unreadStatus.$recipientId': true,
    });

    await batch.commit();
  }

  /// Mark conversation as read for a user
  static Future<void> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    await _firestore.collection('chats').doc(conversationId).update({
      'unreadStatus.$userId': false,
    });

    // Mark messages as read - simplified without composite index
    final messagesQuery = await _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesQuery.docs) {
      final message = doc.data();
      if (message['senderId'] != userId && message['isRead'] == false) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  /// Get unread conversation count for a user - simplified
  static Stream<int> getUnreadConversationCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      // Filter in memory instead of using composite query
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final unreadStatus =
            Map<String, dynamic>.from(data['unreadStatus'] ?? {});
        return unreadStatus[userId] == true;
      }).length;
    });
  }

  /// Delete a conversation
  static Future<void> deleteConversation(String conversationId) async {
    final messagesQuery = await _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesQuery.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_firestore.collection('chats').doc(conversationId));

    await batch.commit();
  }
}
