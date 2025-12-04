import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:trash_dash_demo/models/message.dart';
import 'package:trash_dash_demo/models/conversation.dart';

class ChatService {
  static const _uuid = Uuid();

  // Boxes
  static Box<Message> get messagesBox => Hive.box<Message>('messages');
  static Box<Conversation> get conversationsBox =>
      Hive.box<Conversation>('conversations');

  /// Get or create a conversation between two users about an item
  static Future<Conversation> getOrCreateConversation({
    required String itemId,
    required String itemName,
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
  }) async {
    // Check if conversation already exists
    final existingConversation = conversationsBox.values.where((conv) {
      return conv.itemId == itemId &&
          conv.participantIds.contains(currentUserId) &&
          conv.participantIds.contains(otherUserId);
    }).toList();

    if (existingConversation.isNotEmpty) {
      return existingConversation.first;
    }

    // Create new conversation
    final conversation = Conversation(
      id: _uuid.v4(),
      itemId: itemId,
      itemName: itemName,
      participantIds: [currentUserId, otherUserId],
      participantNames: [currentUserName, otherUserName],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    await conversationsBox.put(conversation.id, conversation);
    return conversation;
  }

  /// Send a message in a conversation
  static Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final message = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      sentAt: DateTime.now(),
    );

    await messagesBox.put(message.id, message);

    // Update conversation's last message
    final conversation = conversationsBox.get(conversationId);
    if (conversation != null) {
      conversation.lastMessageAt = message.sentAt;
      conversation.lastMessageContent = content;
      conversation.lastMessageSenderId = senderId;
      await conversationsBox.put(conversationId, conversation);
    }

    return message;
  }

  /// Get all messages in a conversation
  static List<Message> getMessages(String conversationId) {
    return messagesBox.values
        .where((msg) => msg.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  /// Get all conversations for a user
  static List<Conversation> getUserConversations(String userId) {
    return conversationsBox.values
        .where((conv) => conv.participantIds.contains(userId))
        .toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  /// Mark all messages in a conversation as read for a user
  static Future<void> markConversationAsRead(
      String conversationId, String userId) async {
    final messages = messagesBox.values
        .where((msg) =>
            msg.conversationId == conversationId && msg.senderId != userId)
        .toList();

    for (var message in messages) {
      if (!message.isRead) {
        message.isRead = true;
        await messagesBox.put(message.id, message);
      }
    }
  }

  /// Get unread message count for a user
  static int getUnreadMessageCount(String userId) {
    // Get user's conversation IDs first
    final userConversationIds = getUserConversations(userId)
        .map((conv) => conv.id)
        .toSet();

    // Single pass through messages, filtering by user's conversations
    return messagesBox.values
        .where((msg) =>
            userConversationIds.contains(msg.conversationId) &&
            msg.senderId != userId &&
            !msg.isRead)
        .length;
  }

  /// Get unread message count for a specific conversation
  static int getUnreadCountForConversation(
      String conversationId, String userId) {
    return messagesBox.values
        .where((msg) =>
            msg.conversationId == conversationId &&
            msg.senderId != userId &&
            !msg.isRead)
        .length;
  }

  /// Delete a conversation and its messages
  static Future<void> deleteConversation(String conversationId) async {
    // Delete all messages in the conversation
    final messagesToDelete = messagesBox.values
        .where((msg) => msg.conversationId == conversationId)
        .toList();

    for (var message in messagesToDelete) {
      await messagesBox.delete(message.id);
    }

    // Delete the conversation
    await conversationsBox.delete(conversationId);
  }

  /// Find a conversation by item ID and participants
  static Conversation? findConversation({
    required String itemId,
    required String userId1,
    required String userId2,
  }) {
    final matches = conversationsBox.values.where((conv) {
      return conv.itemId == itemId &&
          conv.participantIds.contains(userId1) &&
          conv.participantIds.contains(userId2);
    }).toList();

    return matches.isNotEmpty ? matches.first : null;
  }
}
