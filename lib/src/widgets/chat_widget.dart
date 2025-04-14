// lib/src/widgets/chat_widget.dart
import 'dart:async'; // For Timer if needed

import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../models/chat_theme.dart';
import 'chat_bubble.dart'; // Ensure ChatBubble is imported

/// A StatefulWidget that provides a complete chat UI.
///
/// It manages the underlying [ChatService], displays messages using [ChatBubble],
/// and provides a text input field for sending messages.
class ChatWidget extends StatefulWidget {
  /// Domain for the chat API backend.
  final String domain;

  /// The specific Chatbot ID to connect to.
  final String chatbotId;

  /// Theme configuration for customizing the chat appearance.
  /// Merged with the application's theme by default.
  final ChatTheme? theme;

  /// Callback invoked when the user successfully sends a message.
  final void Function(String message)? onMessageSent;

  /// Callback invoked when a complete response (content part) is received.
  /// Note: The UI updates reactively; this is for external logic if needed.
  final void Function(String response)? onResponseReceived;

  /// Callback for when citations are received (optional).
  final void Function(List<Map<String, dynamic>> citations)?
      onCitationsReceived;

  /// Callback for when a new thread ID is received (optional).
  final void Function(String threadId)? onThreadIdReceived;

  /// Callback invoked when any error occurs during initialization or message handling.
  final void Function(dynamic error)? onError;

  /// A list of messages to display initially when the widget loads.
  final List<ChatMessage>? initialMessages;

  /// Placeholder text displayed in the message input field.
  final String? inputPlaceholder;

  /// Custom icon for the send button. Defaults to `Icons.send`.
  final IconData? sendButtonIcon;

  /// Whether to display timestamps next to each message bubble.
  final bool showTimestamps;

  /// If true, forces the use of the provided [theme] exclusively,
  /// ignoring the application's `ThemeData`. Defaults to false.
  final bool useThemeOverride;

  /// Flag to control the visibility of citations within the chat bubbles.
  final bool showCitations;

  /// Flag to enable/disable the entire chat widget functionality.
  /// If disabled, input is blocked, and initialization might not occur.
  final bool isEnabled;

  const ChatWidget({
    super.key,
    required this.domain,
    required this.chatbotId,
    this.theme,
    this.onMessageSent,
    this.onResponseReceived,
    this.onCitationsReceived, // Add callback
    this.onThreadIdReceived, // Add callback
    this.onError,
    this.initialMessages,
    this.inputPlaceholder,
    this.sendButtonIcon,
    this.showTimestamps = false,
    this.useThemeOverride = false,
    this.showCitations = false, // Default citations off
    this.isEnabled = true, // Default enabled
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  // Use late final for service if not passing ChatPlugin externally
  late final ChatService _chatService;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  ChatTheme _effectiveTheme =
      const ChatTheme(); // Start with default empty theme
  bool _isInitialized = false; // Track initialization state
  bool _initialMessagesAdded = false; // Ensure initial messages added only once

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(); // Initialize the service here
    _chatService.addListener(_serviceListener); // Listen for state changes

    // Compute initial theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateEffectiveTheme();
      _initializeChatIfNeeded(); // Attempt initial initialization
    });
  }

  // Listener for ChatService changes (like isLoading)
  void _serviceListener() {
    // Trigger rebuild if isLoading changes
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update theme when dependencies (like Theme.of(context)) change
    // This ensures theme updates correctly if the app's theme changes dynamically
    _updateEffectiveTheme();
  }

  @override
  void didUpdateWidget(ChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool configChanged = oldWidget.domain != widget.domain ||
        oldWidget.chatbotId != widget.chatbotId;
    bool enablementChanged = oldWidget.isEnabled != widget.isEnabled;

    // Re-initialize if core config changes OR if it was disabled and now enabled
    if (widget.isEnabled && (configChanged || !oldWidget.isEnabled)) {
      _isInitialized = false; // Mark for re-initialization
      _initialMessagesAdded =
          false; // Allow initial messages again if config changed
      // Clear previous state before initializing again
      _chatService.clearMessages(); // Clear messages associated with old config
      _initializeChatIfNeeded(); // Trigger initialization
    } else if (!widget.isEnabled && oldWidget.isEnabled) {
      // If disabling, clear messages and cancel streams

      _chatService.clearMessages();
      // Note: The service's dispose handles stream cancellation.
      _isInitialized = false; // Mark as uninitialized
      _initialMessagesAdded = false;
      if (mounted) setState(() {}); // Update UI to show disabled state
    }

    // Update theme if theme-related props change
    if (oldWidget.theme != widget.theme ||
        oldWidget.useThemeOverride != widget.useThemeOverride) {
      _updateEffectiveTheme();
      if (mounted) setState(() {}); // Rebuild with new theme
    }
  }

  /// Calculates the effective theme based on app theme and widget properties.
  void _updateEffectiveTheme() {
    if (!mounted) return; // Don't update if not mounted

    final appTheme = Theme.of(context);
    ChatTheme calculatedTheme;

    if (widget.useThemeOverride && widget.theme != null) {
      // Use only the provided theme
      calculatedTheme = widget.theme!;
    } else {
      // Start with theme derived from app context
      final baseTheme = ChatTheme.fromTheme(appTheme);
      // Merge with the widget's specific theme if provided
      calculatedTheme = baseTheme.merge(widget.theme);
    }

    // Only update state if the theme actually changed
    if (_effectiveTheme != calculatedTheme) {
      if (mounted) {
        setState(() {
          _effectiveTheme = calculatedTheme;
        });
      } else {
        // If called before mount or after dispose, just store it
        _effectiveTheme = calculatedTheme;
      }
    }
  }

  /// Initializes the chat service if enabled and not already initialized.
  Future<void> _initializeChatIfNeeded() async {
    // Prevent multiple initializations and initialization if disabled or disposed
    if (!widget.isEnabled || _isInitialized || !mounted) {
      return;
    }

    if (mounted) setState(() {}); // Show loading indicator maybe

    try {
      await _chatService.initialize(
        domain: widget.domain,
        chatbotId: widget.chatbotId,
      );
      if (!mounted) return; // Check mount status *after* await

      _isInitialized = true;

      // Add initial messages *after* successful initialization
      if (!_initialMessagesAdded &&
          widget.initialMessages != null &&
          widget.initialMessages!.isNotEmpty) {
        for (final message in widget.initialMessages!) {
          _chatService.addDirectMessage(message);
        }
        _initialMessagesAdded = true;
        _scrollToBottom(
            instant: true); // Scroll down after adding initial messages
      }

      if (mounted) setState(() {}); // Update UI to reflect initialized state
    } catch (e, stackTrace) {
      if (!mounted) return; // Check mount status *after* await catch

      _isInitialized = false; // Stay uninitialized on error
      if (widget.onError != null) {
        widget.onError!(e);
      } else {
        // Show error in UI if no external handler
        _chatService.addDirectMessage(ChatMessage(
            message:
                "Failed to connect to chat.\nPlease check configuration.", // User-friendly message
            // message: "Initialization Error: $e", // Debug message
            isUser: false,
            type: 'error',
            timestamp: DateTime.now()));
      }
      if (mounted)
        setState(() {}); // Update UI to show error/uninitialized state
    }
  }

  /// Handles sending the message from the input field.
  void _sendMessage() {
    // Guard against sending if disabled, not ready, or already loading
    if (!widget.isEnabled || !_isInitialized || _chatService.isLoading) return;

    final messageText = _textController.text.trim();
    if (messageText.isEmpty) return;

    // Call user callback immediately
    widget.onMessageSent?.call(messageText);

    // Clear input field and unfocus
    _textController.clear();
    FocusScope.of(context).unfocus();

    // Trigger the service to send the message
    _chatService.sendMessage(
      messageText,
      // Pass callbacks from widget to service if needed for external handling
      onResponseContent: widget.onResponseReceived, // Pass the callback
      onCitationsReceived: widget.onCitationsReceived,
      onThreadIdReceived: widget.onThreadIdReceived,
      onError: (error) {
        // Service already adds error message to list. Call external handler.
        widget.onError?.call(error);
        // Optionally show a snackbar or other feedback
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $error")));
      },
    );

    // Scroll to bottom optimistically after sending user message
    _scrollToBottom();
  }

  /// Scrolls the message list to the bottom.
  void _scrollToBottom({bool instant = false}) {
    // Needs to run after the frame is built to have correct scroll metrics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (instant) {
          _scrollController.jumpTo(maxScroll);
        } else {
          _scrollController.animateTo(
            maxScroll, // Scroll to the actual bottom
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  /// Builds a single message item using ChatBubble.
  Widget _buildMessageItem(ChatMessage message, int index, int totalMessages) {
    // Filter out messages that shouldn't be displayed
    if (message.type == 'metadata') {
      return const SizedBox.shrink(); // Don't display metadata types
    }

    bool isError = message.type == 'error';

    // Example: Determine if avatar should be shown (only for last message from a sender block)
    bool showAvatar = false;
    // if (!message.isUser) {
    //   bool isLastBotMessage = (index == totalMessages - 1) || (index < totalMessages - 1 && _chatService.messages[index + 1].isUser);
    //   showAvatar = isLastBotMessage;
    // }

    return ChatBubble(
      key: ValueKey(message.timestamp.toString() +
          message.message), // Key for better list updates
      message: message,
      theme: _effectiveTheme, // Pass the calculated effective theme
      showTimestamp: widget.showTimestamps,
      showCitations: widget.showCitations, // Pass the citation visibility flag
      isError: isError, // Pass error flag for styling
      showAvatar: showAvatar, // Control avatar visibility
      // Add other customizations if needed:
      // avatar: message.isUser ? Icon(Icons.person) : Icon(Icons.support_agent),
      // senderName: message.isUser ? "You" : "Assistant",
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure theme is up-to-date before building
    // Note: Theme is primarily updated in didChangeDependencies and didUpdateWidget
    // _updateEffectiveTheme(); // Less ideal here, prefer reactive updates

    final bool canSend =
        widget.isEnabled && _isInitialized && !_chatService.isLoading;

    return Container(
      // Use theme background color or fallback to scaffold background
      color: _effectiveTheme.backgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Message List Area
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context)
                  .unfocus(), // Dismiss keyboard on tap list
              child: ListenableBuilder(
                listenable:
                    _chatService, // Rebuilds when messages or isLoading changes
                builder: (context, _) {
                  // Auto-scroll when new messages are added (list length changes)
                  // Note: Might need adjustments if updates happen without length change
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      // && _scrollController.position.atEdge - might be needed
                      _scrollToBottom();
                    }
                  });

                  // --- UI States ---
                  if (!widget.isEnabled) {
                    return const Center(
                        child: Text("Chat is disabled.",
                            style: TextStyle(color: Colors.grey)));
                  }
                  if (!_isInitialized && !_chatService.isLoading) {
                    // Show a connecting message or a button to retry
                    // Check if there's an initialization error message
                    final initError = _chatService.messages.firstWhere(
                        (m) => m.type == 'error',
                        orElse: () =>
                            const ChatMessage(message: '', isUser: false));
                    if (initError.message.isNotEmpty) {
                      return Center(
                          child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(initError.message,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ));
                    } else {
                      return const Center(
                          child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text("Connecting...")
                        ],
                      ));
                    }
                  }
                  // --- End UI States ---

                  final messages = _chatService.messages;
                  return ListView.builder(
                    controller: _scrollController,
                    // reverse: true, // Keep false if scrolling to maxScrollExtent
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 8.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      // Pass index and total count for potential conditional styling (e.g., avatars)
                      return _buildMessageItem(message, index, messages.length);
                    },
                  );
                },
              ),
            ),
          ),
          // Input Area Divider
          if (widget.isEnabled)
            Divider(
              height: 1,
              thickness: 1,
              color:
                  Theme.of(context).dividerColor.withAlpha((255 * 0.5).round()),
            ),

          // Input Area Container
          if (widget.isEnabled)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              color: Theme.of(context)
                  .canvasColor, // Use canvasColor for input area background
              child: Row(
                crossAxisAlignment: CrossAxisAlignment
                    .end, // Align items to bottom for multiline
                children: [
                  // Input Text Field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: canSend,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 5, // Allow multi-line input
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color), // Use default text style color
                      decoration: _effectiveTheme.inputDecoration ??
                          InputDecoration(
                            hintText:
                                widget.inputPlaceholder ?? 'Type a message...',
                            hintStyle:
                                TextStyle(color: Theme.of(context).hintColor),
                            border: InputBorder.none, // Remove default border
                            filled:
                                true, // Need filled true for color or decoration
                            fillColor:
                                Colors.transparent, // Make fill transparent
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            // Ensure no borders when disabled
                            disabledBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                          ),
                      // Send on software keyboard action
                      onSubmitted: canSend ? (_) => _sendMessage() : null,
                      textInputAction: TextInputAction.send,
                      // Rebuild send button state when text changes
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8), // Spacing
                  // Send Button / Loading Indicator
                  SizedBox(
                    height: 48, // Ensure consistent button height
                    width: 48,
                    child: IconButton(
                      padding: EdgeInsets.zero, // Remove default padding
                      icon: _chatService.isLoading
                          ? SizedBox(
                              // Show spinner when loading
                              width: 24,
                              height: 24, // Control spinner size
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _effectiveTheme.sendButtonDisabledColor ??
                                        Theme.of(context).disabledColor),
                              ))
                          : Icon(widget.sendButtonIcon ?? Icons.send),
                      // Determine button color based on state
                      color: canSend &&
                              _textController.text
                                  .isNotEmpty // Enable color only if canSend AND has text
                          ? (_effectiveTheme.sendButtonColor ??
                              Theme.of(context).colorScheme.primary)
                          : (_effectiveTheme.sendButtonDisabledColor ??
                              Theme.of(context).disabledColor),
                      // Enable onPressed only if canSend AND has text
                      onPressed: (canSend && _textController.text.isNotEmpty)
                          ? _sendMessage
                          : null,
                      tooltip: canSend
                          ? "Send message"
                          : (_chatService.isLoading
                              ? "Sending..."
                              : (_isInitialized
                                  ? "Enter a message"
                                  : "Chat not ready")),
                      splashRadius: 24, // Adjust splash radius
                    ),
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
    _chatService.removeListener(_serviceListener); // Remove listener
    _chatService.dispose(); // Dispose the service (cancels streams, etc.)
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
