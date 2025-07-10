class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  ChatMessageModel({required this.id, required this.chatId, required this.senderId, required this.message, required this.createdAt});

  ChatMessageModel copyWith(String? id, String? chatId, String? senderId, String? message, DateTime? createdAt) {
    return ChatMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      message: json['message'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['last_activity_at'] * 1000),
    );
  }
}
