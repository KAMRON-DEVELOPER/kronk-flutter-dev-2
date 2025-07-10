class ParticipantModel {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final DateTime? lastSeenAt;
  final bool? isOnline;

  ParticipantModel({required this.id, required this.name, required this.username, this.avatarUrl, this.lastSeenAt, this.isOnline});

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      lastSeenAt: json['last_seen_at'] != null ? DateTime.fromMillisecondsSinceEpoch(json['avatar_url'] * 1000) : null,
      isOnline: json['is_online'],
    );
  }

  ParticipantModel copyWith({DateTime? lastSeenAt, bool? isOnline}) {
    return ParticipantModel(id: id, name: name, username: username, avatarUrl: avatarUrl, lastSeenAt: lastSeenAt ?? this.lastSeenAt, isOnline: isOnline ?? this.isOnline);
  }
}

class ChatModel {
  final String id;
  final ParticipantModel participant;
  final DateTime lastActivityAt;
  final String lastMessage;

  ChatModel({required this.id, required this.participant, required this.lastActivityAt, required this.lastMessage});

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      participant: ParticipantModel.fromJson(json['participant']),
      lastActivityAt: DateTime.fromMillisecondsSinceEpoch(json['last_activity_at'] * 1000),
      lastMessage: json['last_message'],
    );
  }

  ChatModel copyWith({String? id, ParticipantModel? participant, DateTime? lastActivityAt, String? lastMessage, bool? lastMessageSeen, int? unreadCount}) {
    return ChatModel(
      id: id ?? this.id,
      participant: participant ?? this.participant,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
