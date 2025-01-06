class ChatMessage {
  final int id;
  final String message;
  final bool isUser;
  final int chatLogId;
  final bool isWaiting;

  const ChatMessage({
    required this.id,
    required this.message,
    required this.isUser,
    required this.chatLogId,
    this.isWaiting = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      message: json['message'] as String,
      isUser: json['isUser'] as bool,
      chatLogId: json['chatLogId'] as int,
      isWaiting: json['isWaiting'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'isUser': isUser,
        'chatLogId': chatLogId,
        'isWaiting': isWaiting,
      };
}
