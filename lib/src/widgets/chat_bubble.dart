// lib/src/widgets/chat_bubble.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_theme.dart';
import 'typing_indicator.dart';

/// Enhanced chat bubble widget for more advanced styling options
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final ChatTheme theme;
  final bool showAvatar;
  final bool showTimestamp;
  final Widget? avatar;
  final String? senderName;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Function()? onTap;
  final Function()? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.theme,
    this.showAvatar = false,
    this.showTimestamp = false,
    this.avatar,
    this.senderName,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final isUser = message.isUser;

    // Get appropriate decoration and text style based on message type
    final decoration = isUser
        ? theme.getUserBubbleDecoration(appTheme)
        : theme.getBotBubbleDecoration(appTheme);

    final textStyle = isUser
        ? theme.getUserTextStyle(appTheme)
        : theme.getBotTextStyle(appTheme);

    final bubbleMargin = margin ??
        EdgeInsets.only(
          left: isUser ? 40 : 8,
          right: isUser ? 8 : 40,
          top: 4,
          bottom: 4,
        );

    final bubblePadding =
        padding ?? const EdgeInsets.symmetric(vertical: 10, horizontal: 14);

    Widget bubbleContent = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: bubblePadding,
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender name if provided
            if (senderName != null && senderName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName!,
                  style: textStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

            // Message content
            Text(
              message.message,
              style: textStyle,
            ),

            // Bubble typing animation indicator
            if (message.isWaiting)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: BubbleTypingIndicator(
                  color: theme.loadingIndicatorColor ??
                      appTheme.colorScheme.primary,
                  bubbleSize: 8,
                  spacing: 4,
                ),
              ),

            // Timestamp if enabled
            if (showTimestamp && message.timestamp != null)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTimestamp(message.timestamp!),
                    style: textStyle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      color: textStyle.color?.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // If showing avatar, create a row with avatar and bubble
    if (showAvatar) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: isUser
              ? [
                  Flexible(child: bubbleContent),
                  const SizedBox(width: 8),
                  avatar ?? _defaultAvatar(isUser, appTheme),
                ]
              : [
                  avatar ?? _defaultAvatar(isUser, appTheme),
                  const SizedBox(width: 8),
                  Flexible(child: bubbleContent),
                ],
        ),
      );
    }

    // Otherwise just return the bubble with alignment
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: bubbleMargin,
        child: bubbleContent,
      ),
    );
  }

  /// Format timestamp to HH:MM format
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Create a default avatar widget
  Widget _defaultAvatar(bool isUser, ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          isUser ? theme.colorScheme.primary : theme.colorScheme.secondary,
      child: Icon(
        isUser ? Icons.person : Icons.support_agent,
        size: 16,
        color: isUser
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSecondary,
      ),
    );
  }
}
