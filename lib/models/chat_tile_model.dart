class ParticipantModel {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool isOnline;

  ParticipantModel({required this.id, required this.name, required this.username, required this.avatarUrl, this.isOnline = false});

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(id: json['id'], name: json['name'], username: json['username'], avatarUrl: json['avatar_url'], isOnline: json['is_online'] ?? false);
  }
}

class ChatTileModel {
  final String id;
  final ParticipantModel participant;
  final DateTime lastActivityAt;
  final String lastMessage;
  final bool lastMessageSeen;
  final int unreadCount;

  ChatTileModel({required this.id, required this.participant, required this.lastActivityAt, required this.lastMessage, required this.lastMessageSeen, required this.unreadCount});

  factory ChatTileModel.fromJson(Map<String, dynamic> json) {
    return ChatTileModel(
      id: json['id'],
      participant: ParticipantModel.fromJson(json['participant']),
      lastActivityAt: DateTime.fromMillisecondsSinceEpoch((json['last_activity_at'] ?? DateTime.now().millisecondsSinceEpoch) * 1000),
      lastMessage: json['last_message'] ?? '',
      lastMessageSeen: json['last_message_seen'] ?? false,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  ChatTileModel copyWith({String? id, ParticipantModel? participant, DateTime? lastActivityAt, String? lastMessage, bool? lastMessageSeen, int? unreadCount}) {
    return ChatTileModel(
      id: id ?? this.id,
      participant: participant ?? this.participant,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSeen: lastMessageSeen ?? this.lastMessageSeen,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
