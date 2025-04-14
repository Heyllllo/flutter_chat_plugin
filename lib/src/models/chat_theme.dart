// lib/src/models/chat_theme.dart
import 'package:flutter/material.dart';

/// Theme configuration for the chat widget
class ChatTheme {
  /// Color of user message bubbles
  final Color? userBubbleColor;

  /// Color of bot message bubbles
  final Color? botBubbleColor;

  /// Text style for user messages
  final TextStyle? userTextStyle;

  /// Text style for bot messages
  final TextStyle? botTextStyle;

  /// Decoration for user message bubbles
  final BoxDecoration? userBubbleDecoration;

  /// Decoration for bot message bubbles
  final BoxDecoration? botBubbleDecoration;

  /// Input field decoration
  final InputDecoration? inputDecoration;

  /// Send button color when active
  final Color? sendButtonColor;

  /// Send button color when disabled
  final Color? sendButtonDisabledColor;

  /// Loading indicator color
  final Color? loadingIndicatorColor;

  /// Background color of the chat area
  final Color? backgroundColor;

  /// Border radius for user message bubbles
  final BorderRadius? userBubbleBorderRadius;

  /// Border radius for bot message bubbles
  final BorderRadius? botBubbleBorderRadius;

  const ChatTheme({
    this.userBubbleColor,
    this.botBubbleColor,
    this.userTextStyle,
    this.botTextStyle,
    this.userBubbleDecoration,
    this.botBubbleDecoration,
    this.inputDecoration,
    this.sendButtonColor,
    this.sendButtonDisabledColor,
    this.loadingIndicatorColor,
    this.backgroundColor,
    this.userBubbleBorderRadius,
    this.botBubbleBorderRadius,
  });

  /// Creates a ChatTheme from a Flutter ThemeData
  /// This allows the chat widget to adopt the app's theme
  factory ChatTheme.fromTheme(ThemeData theme) {
    return ChatTheme(
      userBubbleColor: theme.colorScheme.primary,
      botBubbleColor: theme.colorScheme.surfaceContainerHighest,
      userTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
      botTextStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      sendButtonColor: theme.colorScheme.primary,
      sendButtonDisabledColor: theme.disabledColor,
      loadingIndicatorColor: theme.colorScheme.primary,
      backgroundColor: theme.scaffoldBackgroundColor,
      userBubbleBorderRadius: BorderRadius.circular(16),
      botBubbleBorderRadius: BorderRadius.circular(16),
    );
  }

  /// Merges this theme with another, preferring values from the other theme when they exist
  ChatTheme merge(ChatTheme? other) {
    if (other == null) return this;

    return ChatTheme(
      userBubbleColor: other.userBubbleColor ?? userBubbleColor,
      botBubbleColor: other.botBubbleColor ?? botBubbleColor,
      userTextStyle: other.userTextStyle ?? userTextStyle,
      botTextStyle: other.botTextStyle ?? botTextStyle,
      userBubbleDecoration: other.userBubbleDecoration ?? userBubbleDecoration,
      botBubbleDecoration: other.botBubbleDecoration ?? botBubbleDecoration,
      inputDecoration: other.inputDecoration ?? inputDecoration,
      sendButtonColor: other.sendButtonColor ?? sendButtonColor,
      sendButtonDisabledColor:
          other.sendButtonDisabledColor ?? sendButtonDisabledColor,
      loadingIndicatorColor:
          other.loadingIndicatorColor ?? loadingIndicatorColor,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      userBubbleBorderRadius:
          other.userBubbleBorderRadius ?? userBubbleBorderRadius,
      botBubbleBorderRadius:
          other.botBubbleBorderRadius ?? botBubbleBorderRadius,
    );
  }

  /// Apply theme with implicit fallbacks to default theme and app theme
  BoxDecoration getUserBubbleDecoration(ThemeData appTheme) {
    if (userBubbleDecoration != null) return userBubbleDecoration!;

    return BoxDecoration(
      color: userBubbleColor ?? appTheme.colorScheme.primary,
      borderRadius: userBubbleBorderRadius ?? BorderRadius.circular(16),
    );
  }

  /// Apply theme with implicit fallbacks to default theme and app theme
  BoxDecoration getBotBubbleDecoration(ThemeData appTheme) {
    if (botBubbleDecoration != null) return botBubbleDecoration!;

    return BoxDecoration(
      color: botBubbleColor ?? appTheme.colorScheme.surfaceContainerHighest,
      borderRadius: botBubbleBorderRadius ?? BorderRadius.circular(16),
    );
  }

  /// Get text style for user messages with fallbacks
  TextStyle getUserTextStyle(ThemeData appTheme) {
    return userTextStyle ??
        TextStyle(
          color: userBubbleColor != null
              ? ThemeData.estimateBrightnessForColor(userBubbleColor!) ==
                      Brightness.dark
                  ? Colors.white
                  : Colors.black
              : appTheme.colorScheme.onPrimary,
        );
  }

  /// Get text style for bot messages with fallbacks
  TextStyle getBotTextStyle(ThemeData appTheme) {
    return botTextStyle ??
        TextStyle(
          color: botBubbleColor != null
              ? ThemeData.estimateBrightnessForColor(botBubbleColor!) ==
                      Brightness.dark
                  ? Colors.white
                  : Colors.black
              : appTheme.colorScheme.onSurfaceVariant,
        );
  }
}
