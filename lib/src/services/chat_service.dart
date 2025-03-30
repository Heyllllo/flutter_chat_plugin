// lib/src/services/chat_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../../chat_plugin.dart';

class ChatService extends ChangeNotifier {
  final ChatPlugin _plugin;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  StreamSubscription? _sseSubscription;

  ChatService() : _plugin = ChatPlugin();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  Future<void> initialize({
    required String domain,
    required String chatbotId,
  }) async {
    await _plugin.initialize(
      domain: domain,
      chatbotId: chatbotId,
    );
  }

  Future<void> sendMessage(
    String message, {
    Function(String response)? onResponse,
    Function(dynamic error)? onError,
  }) async {
    if (message.trim().isEmpty) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Add user message with timestamp
      _addMessage(ChatMessage(
        message: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));

      // Create placeholder for AI response
      final placeholderMessage = ChatMessage(
        message: '',
        isUser: false,
        isWaiting: true,
        timestamp: DateTime.now(),
      );
      _addMessage(placeholderMessage);

      // Start streaming response
      _streamResponse(
        message: message,
        onResponse: onResponse,
        onError: onError,
      );
    } catch (e) {
      print('Error in sendMessage: $e');
      if (onError != null) {
        onError(e);
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  void _streamResponse({
    required String message,
    Function(String response)? onResponse,
    Function(dynamic error)? onError,
  }) {
    _sseSubscription?.cancel();

    // Get the index of the placeholder message (should be the last message)
    final placeholderIndex = _messages.length - 1;
    String responseText = '';

    // Max time to wait for response before timing out
    Timer? timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_sseSubscription != null) {
        _sseSubscription?.cancel();
        _isLoading = false;

        // Update placeholder with timeout message
        if (placeholderIndex < _messages.length) {
          _messages[placeholderIndex] = _messages[placeholderIndex].copyWith(
            message: 'The server took too long to respond. Please try again.',
            isWaiting: false,
          );
        }

        if (onError != null) {
          onError('Request timed out after 30 seconds');
        }

        notifyListeners();
      }
    });

    _sseSubscription = _plugin
        .streamResponse(
      message: message,
    )
        .listen(
      (chunk) {
        // Cancel timeout timer since we got a response
        timeoutTimer.cancel();

        // Accumulate the response text
        responseText += chunk;

        if (placeholderIndex < _messages.length) {
          _messages[placeholderIndex] = _messages[placeholderIndex].copyWith(
            message: responseText,
            isWaiting: false,
          );
          notifyListeners();
        }
      },
      onError: (error) {
        print('Error in streamResponse: $error');

        // Cancel timeout timer since we got an error response
        timeoutTimer.cancel();

        // Extract error message from exception
        String errorMessage = error.toString();

        // Try to make error message more user-friendly
        if (errorMessage.contains('SpaceNotFound')) {
          errorMessage = 'The chatbot ID was not found on the server.';
        } else if (errorMessage.contains('500')) {
          errorMessage = 'The server encountered an internal error.';
        } else if (errorMessage.contains('404')) {
          errorMessage = 'The chatbot service could not be found.';
        } else if (errorMessage.contains('403')) {
          errorMessage = 'Access to this chatbot is forbidden.';
        }

        // Update the placeholder message to show the error
        if (placeholderIndex < _messages.length) {
          _messages[placeholderIndex] = _messages[placeholderIndex].copyWith(
            message: 'Error: $errorMessage',
            isWaiting: false,
          );
        }

        // Call the error callback if provided
        if (onError != null) {
          onError(error);
        }

        _isLoading = false;
        notifyListeners();
      },
      onDone: () {
        // Cancel timeout timer since the stream is done
        timeoutTimer.cancel();

        // Call the onResponse callback with the final text if provided
        if (onResponse != null && responseText.isNotEmpty) {
          onResponse(responseText);
        }

        _sseSubscription = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  /// Add a message directly to the chat (for initial messages or system messages)
  void addDirectMessage(ChatMessage message) {
    // Add timestamp if not provided
    final timestampedMessage = message.timestamp == null
        ? message.copyWith(timestamp: DateTime.now())
        : message;

    _messages.add(timestampedMessage);
    notifyListeners();
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _plugin.dispose();
    super.dispose();
  }
}
