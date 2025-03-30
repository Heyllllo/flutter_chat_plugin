// lib/src/models/chat_message.dart
class ChatMessage {
  final String message;
  final bool isUser;
  final bool isWaiting;
  final DateTime? timestamp;

  const ChatMessage({
    required this.message,
    required this.isUser,
    this.isWaiting = false,
    this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      message: json['message'] as String,
      isUser: json['isUser'] as bool,
      isWaiting: json['isWaiting'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'isUser': isUser,
        'isWaiting': isWaiting,
        'timestamp': timestamp?.toIso8601String(),
      };

  /// Create a copy of this message with updated fields
  ChatMessage copyWith({
    String? message,
    bool? isUser,
    bool? isWaiting,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      message: message ?? this.message,
      isUser: isUser ?? this.isUser,
      isWaiting: isWaiting ?? this.isWaiting,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
