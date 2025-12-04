import 'package:hive/hive.dart';

part 'conversation.g.dart';

@HiveType(typeId: 5)
class Conversation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String itemId;

  @HiveField(2)
  final String itemName;

  @HiveField(3)
  final List<String> participantIds;

  @HiveField(4)
  final List<String> participantNames;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  DateTime lastMessageAt;

  @HiveField(7)
  String? lastMessageContent;

  @HiveField(8)
  String? lastMessageSenderId;

  Conversation({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.participantIds,
    required this.participantNames,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessageContent,
    this.lastMessageSenderId,
  });

  /// Get the other participant's name (for display purposes)
  String getOtherParticipantName(String currentUserId) {
    final index = participantIds.indexOf(currentUserId);
    if (index == -1 || participantNames.length < 2) {
      return participantNames.isNotEmpty ? participantNames.first : 'Unknown';
    }
    // Return the name at the opposite index
    return participantNames[index == 0 ? 1 : 0];
  }

  /// Get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    final index = participantIds.indexOf(currentUserId);
    if (index == -1 || participantIds.length < 2) {
      return participantIds.isNotEmpty ? participantIds.first : '';
    }
    return participantIds[index == 0 ? 1 : 0];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'lastMessageContent': lastMessageContent,
      'lastMessageSenderId': lastMessageSenderId,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: List<String>.from(map['participantNames'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      lastMessageAt: DateTime.parse(map['lastMessageAt']),
      lastMessageContent: map['lastMessageContent'],
      lastMessageSenderId: map['lastMessageSenderId'],
    );
  }
}
