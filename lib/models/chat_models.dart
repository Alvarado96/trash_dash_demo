import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String? itemId;
  final String? itemName;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final String? lastMessageSenderId;
  final Map<String, bool> unreadStatus; // {userId: hasUnread}
  final DateTime createdAt;

  ChatConversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.itemId,
    this.itemName,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.lastMessageSenderId,
    required this.unreadStatus,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'itemId': itemId,
      'itemName': itemName,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp != null
          ? Timestamp.fromDate(lastMessageTimestamp!)
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadStatus': unreadStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNames:
          Map<String, String>.from(data['participantNames'] ?? {}),
      itemId: data['itemId'],
      itemName: data['itemName'],
      lastMessage: data['lastMessage'],
      lastMessageTimestamp:
          (data['lastMessageTimestamp'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadStatus: Map<String, bool>.from(data['unreadStatus'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String getOtherParticipantName(String currentUserId) {
    final otherUserId = getOtherParticipantId(currentUserId);
    return participantNames[otherUserId] ?? 'Unknown';
  }

  bool hasUnreadMessages(String userId) {
    return unreadStatus[userId] ?? false;
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }
}
