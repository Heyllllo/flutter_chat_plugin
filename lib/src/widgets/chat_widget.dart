// lib/src/widgets/chat_widget.dart
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../models/chat_theme.dart';
import 'typing_indicator.dart';

class ChatWidget extends StatefulWidget {
  /// Domain for the chat API
  final String domain;

  /// Chatbot ID to connect to
  final String chatbotId;

  /// Theme configuration for the chat widget
  final ChatTheme? theme;

  /// Callback when a new message is sent
  final void Function(String message)? onMessageSent;

  /// Callback when a response is received
  final void Function(String response)? onResponseReceived;

  /// Callback when an error occurs
  final void Function(dynamic error)? onError;

  /// Initial messages to display
  final List<ChatMessage>? initialMessages;

  /// Placeholder text for the input field
  final String? inputPlaceholder;

  /// Custom send button icon
  final IconData? sendButtonIcon;

  /// Whether to show timestamps on messages
  final bool showTimestamps;

  /// Override the app's theme (not recommended)
  final bool useThemeOverride;

  const ChatWidget({
    super.key,
    required this.domain,
    required this.chatbotId,
    this.theme,
    this.onMessageSent,
    this.onResponseReceived,
    this.onError,
    this.initialMessages,
    this.inputPlaceholder,
    this.sendButtonIcon,
    this.showTimestamps = false,
    this.useThemeOverride = false,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final _chatService = ChatService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late ChatTheme _effectiveTheme;

  @override
  void initState() {
    super.initState();
    _initializeChat();

    // Set initial messages if provided
    if (widget.initialMessages != null && widget.initialMessages!.isNotEmpty) {
      for (final message in widget.initialMessages!) {
        _chatService.addDirectMessage(message);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update effective theme based on app theme
    _updateEffectiveTheme();
  }

  @override
  void didUpdateWidget(ChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      _updateEffectiveTheme();
    }
  }

  void _updateEffectiveTheme() {
    final appTheme = Theme.of(context);

    if (widget.useThemeOverride && widget.theme != null) {
      // Use only the provided theme, ignoring app theme
      _effectiveTheme = widget.theme!;
    } else {
      // Merge app theme and provided theme
      final baseTheme = ChatTheme.fromTheme(appTheme);
      _effectiveTheme = baseTheme.merge(widget.theme);
    }
  }

  Future<void> _initializeChat() async {
    await _chatService.initialize(
      domain: widget.domain,
      chatbotId: widget.chatbotId,
    );
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;

    final message = _textController.text;

    // Call onMessageSent callback if provided
    if (widget.onMessageSent != null) {
      widget.onMessageSent!(message);
    }

    _chatService.sendMessage(
      message,
      onResponse: widget.onResponseReceived,
      onError: (error) {
        // Call onError callback if provided
        if (widget.onError != null) {
          widget.onError!(error);
        }
      },
    );

    _textController.clear();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    // Get appropriate decoration and text style based on message type
    final decoration = isUser
        ? _effectiveTheme.getUserBubbleDecoration(theme)
        : _effectiveTheme.getBotBubbleDecoration(theme);

    final textStyle = isUser
        ? _effectiveTheme.getUserTextStyle(theme)
        : _effectiveTheme.getBotTextStyle(theme);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: textStyle,
            ),
            if (message.isWaiting)
              BubbleTypingIndicator(
                color: _effectiveTheme.loadingIndicatorColor,
                bubbleSize: 8,
                spacing: 4,
              ),
            if (widget.showTimestamps && message.timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTimestamp(message.timestamp!),
                  style: textStyle.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Update theme if needed
    _updateEffectiveTheme();

    return Container(
      color: _effectiveTheme.backgroundColor,
      child: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: _chatService,
              builder: (context, _) {
                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _chatService.messages.length,
                  itemBuilder: (context, index) {
                    final message = _chatService
                        .messages[_chatService.messages.length - 1 - index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: _effectiveTheme.inputDecoration ??
                        InputDecoration(
                          hintText:
                              widget.inputPlaceholder ?? 'Type a message...',
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    widget.sendButtonIcon ?? Icons.send,
                    color: _chatService.isLoading
                        ? _effectiveTheme.sendButtonDisabledColor
                        : _effectiveTheme.sendButtonColor,
                  ),
                  onPressed: _chatService.isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
