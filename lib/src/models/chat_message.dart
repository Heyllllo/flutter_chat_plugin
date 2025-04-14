// lib/src/models/chat_message.dart
// Import for kDebugMode if needed later

class ChatMessage {
  final String message; // 'text' for content, description for others
  final bool isUser;
  final bool isWaiting;
  final DateTime? timestamp;
  final String type; // Add type: 'content', 'metadata', 'citation', 'error'
  final String? threadId; // Add threadId
  final List<Map<String, dynamic>>? citations; // Add citations list

  const ChatMessage({
    required this.message,
    required this.isUser,
    this.isWaiting = false,
    this.timestamp,
    this.type =
        'content', // Default to content for user messages or direct adds
    this.threadId,
    this.citations,
  });

  // Keep factory ChatMessage.fromJson and toJson if needed for local persistence,
  // but backend parsing is handled in the service/method channel.
  // Example for local persistence (optional):
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      message: json['message'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      isWaiting: json['isWaiting'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String? ?? '')
          : null,
      type: json['type'] as String? ?? 'content',
      threadId: json['threadId'] as String?,
      // Ensure citations are List<Map<String, dynamic>>
      citations: (json['citations'] as List<dynamic>?)
          ?.map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'isUser': isUser,
        'isWaiting': isWaiting,
        'timestamp': timestamp?.toIso8601String(),
        'type': type,
        'threadId': threadId,
        'citations': citations,
      };
  // End optional persistence methods

  /// Create a copy of this message with updated fields
  ChatMessage copyWith({
    String? message,
    bool? isUser,
    bool? isWaiting,
    DateTime? timestamp,
    String? type,
    // Use Object() as a sentinel for nulling the value if needed, otherwise standard null means no change
    Object? threadId = const Object(),
    Object? citations = const Object(), // Use Object() as sentinel for nulling
    bool? clearCitations, // Explicit flag to clear citations
  }) {
    // Determine final citations based on flags and input
    List<Map<String, dynamic>>? finalCitations;
    if (clearCitations == true) {
      finalCitations = null;
    } else if (citations is List<Map<String, dynamic>>?) {
      // Explicitly passed citations (could be null)
      finalCitations = citations;
    } else {
      // Sentinel means no change from original
      finalCitations = this.citations;
    }

    return ChatMessage(
      message: message ?? this.message,
      isUser: isUser ?? this.isUser,
      isWaiting: isWaiting ?? this.isWaiting,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      // Handle threadId update or removal
      threadId: threadId is String?
          ? threadId
          : (threadId == const Object() ? this.threadId : null),
      citations: finalCitations,
    );
  }
}
