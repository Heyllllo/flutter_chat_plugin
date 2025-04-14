// lib/src/services/chat_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../chat_plugin.dart';

class ChatService extends ChangeNotifier {
  final ChatPlugin _plugin;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  StreamSubscription<Map<String, dynamic>>? _sseSubscription;
  String? _currentThreadId;

  ChatService({ChatPlugin? plugin}) : _plugin = plugin ?? ChatPlugin();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get currentThreadId => _currentThreadId;

  // ... (initialize, sendMessage methods remain largely the same) ...
  Future<void> initialize({
    required String domain,
    required String chatbotId,
  }) async {
    _setLoading(false);
    await _sseSubscription?.cancel();
    _sseSubscription = null;
    _messages.clear();
    _currentThreadId = null;
    try {
      await _plugin.initialize(domain: domain, chatbotId: chatbotId);

      notifyListeners();
    } catch (e) {
      _addMessage(ChatMessage(
          message: 'Error initializing chat: $e',
          isUser: false,
          type: 'error',
          timestamp: DateTime.now()));
      rethrow;
    }
  }

  Future<void> sendMessage(
    String message, {
    Function(String accumulatedText)? onResponseContent,
    Function(List<Map<String, dynamic>> citations)? onCitationsReceived,
    Function(String threadId)? onThreadIdReceived,
    Function(dynamic error)? onError,
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;
    if (_isLoading) {
      if (onError != null) onError("Please wait...");
      return;
    }
    _setLoading(true);
    try {
      final userMessage = ChatMessage(
          message: trimmedMessage,
          isUser: true,
          timestamp: DateTime.now(),
          type: 'content');
      _addMessage(userMessage);

      final placeholderIndex = _messages.length;
      final placeholderMessage = ChatMessage(
          message: '',
          isUser: false,
          isWaiting: true,
          timestamp: DateTime.now(),
          type: 'content');
      _addMessage(placeholderMessage);

      await _sseSubscription?.cancel();
      _sseSubscription = null;

      _streamResponse(
          message: trimmedMessage,
          threadId: _currentThreadId,
          placeholderIndex: placeholderIndex,
          onResponseContent: onResponseContent,
          onCitationsReceived: onCitationsReceived,
          onThreadIdReceived: onThreadIdReceived,
          onError: onError);
    } catch (e) {
      _handleError('Failed to send message: $e', _messages.length - 1);
      if (onError != null) onError(e);
      _setLoading(false);
    }
  }

  // --- Completion Logic Helper ---
  // Moved logic out to be callable from onData (for stream_end) and onDone
  void _finalizeResponse(int placeholderIndex, String accumulatedText,
      List<Map<String, dynamic>> citations,
      {Function(String accumulatedText)? onResponseContent}) {
    // Update the message, ensuring isWaiting is false
    _updateMessage(placeholderIndex, (msg) {
      final finalType = msg.type == 'error'
          ? 'error'
          : 'content'; // Keep error type if it was set
      final finalMessage =
          accumulatedText.isNotEmpty ? accumulatedText : msg.message;

      return msg.copyWith(
          isWaiting: false, // <<< SETTING TO FALSE >>>
          message: finalMessage,
          citations: citations.isNotEmpty ? citations : msg.citations,
          type: finalType);
    });

    // Check if the final message should be removed
    final finalMessageState =
        (placeholderIndex >= 0 && placeholderIndex < _messages.length)
            ? _messages[placeholderIndex]
            : null;
    if (finalMessageState != null &&
        finalMessageState.message.trim().isEmpty &&
        (finalMessageState.citations?.isEmpty ?? true) &&
        finalMessageState.type != 'error') {
      // Be careful modifying list while iterating or using index directly after removal
      // It's safer to remove *after* potential UI updates using this index are done, or use other logic.
      // For simplicity here, we assume removal is okay. Consider marking for removal if issues arise.
      _messages.removeAt(placeholderIndex);
      notifyListeners(); // Notify about removal
    }

    // Trigger final response callback *after* message state is updated
    if (onResponseContent != null && accumulatedText.isNotEmpty) {
      onResponseContent(accumulatedText);
    }

    _sseSubscription = null; // Clear subscription ref
    _setLoading(false); // Set overall loading false
  }
  // --- End Completion Logic Helper ---

  void _streamResponse({
    required String message,
    String? threadId,
    required int placeholderIndex,
    Function(String accumulatedText)? onResponseContent,
    Function(List<Map<String, dynamic>> citations)? onCitationsReceived,
    Function(String threadId)? onThreadIdReceived,
    Function(dynamic error)? onError,
  }) {
    String accumulatedResponseText = '';
    List<Map<String, dynamic>> currentCitations = [];
    bool receivedData = false;
    bool streamEndedPrematurely = false; // Flag to prevent double finalization

    final timeoutDuration = const Duration(seconds: 60);
    Timer? timeoutTimer =
        Timer(timeoutDuration, () {/* ... timeout logic ... */});

    try {
      _sseSubscription = _plugin
          .streamResponse(
        message: message,
        threadId: threadId,
      )
          .listen(
        (data) {
          if (streamEndedPrematurely) return; // Don't process if already ended

          if (!receivedData) {
            receivedData = true;
            timeoutTimer.cancel();
          }

          // if (kDebugMode)
          //   print(
          //       'ChatService [_streamResponse][onData]: Data for index $placeholderIndex: $data');

          final type = data['type'] as String?;

          try {
            switch (type) {
              // *** HANDLE STREAM_END EVENT HERE ***
              case 'stream_end':
                timeoutTimer.cancel(); // Cancel timer
                streamEndedPrematurely = true; // Set flag
                _finalizeResponse(
                    placeholderIndex, accumulatedResponseText, currentCitations,
                    onResponseContent: onResponseContent);
                _sseSubscription?.cancel(); // Cancel subscription manually
                _sseSubscription = null;
                return; // Stop processing this event further

              case 'metadata':
                final newThreadId = data['thread_id']?.toString();
                if (newThreadId != null &&
                    newThreadId.isNotEmpty &&
                    newThreadId != _currentThreadId) {
                  _currentThreadId = newThreadId;
                  if (onThreadIdReceived != null) {
                    onThreadIdReceived(newThreadId);
                  }
                }
                break;
              case 'content':
                final textChunk = data['text'] as String? ?? '';
                if (textChunk.isNotEmpty) {
                  accumulatedResponseText += textChunk;
                  // Don't call onResponseContent here anymore
                  _updateMessage(
                      placeholderIndex,
                      (msg) => msg.copyWith(
                          message: accumulatedResponseText,
                          isWaiting: true,
                          type: 'content'));
                }
                break;
              case 'citations':
                final citationsData = data['citations'] as List<dynamic>?;
                if (citationsData != null) {
                  final newCitations = citationsData
                      .whereType<Map>()
                      .map((item) => Map<String, dynamic>.from(item))
                      .toList();
                  if (newCitations.isNotEmpty) {
                    currentCitations.addAll(newCitations);
                    _updateMessage(
                        placeholderIndex,
                        (msg) => msg.copyWith(
                            citations: List.from(msg.citations ?? [])
                              ..addAll(newCitations)));
                    if (onCitationsReceived != null) {
                      onCitationsReceived(currentCitations);
                    }
                  }
                }
                break;
              case 'error':
                final errorMessage =
                    data['message'] as String? ?? 'Unknown server error';

                timeoutTimer.cancel();
                streamEndedPrematurely = true;
                _handleError(errorMessage, placeholderIndex,
                    errorDetails: data['error_details'] as String?);
                if (onError != null) onError(errorMessage);
                _sseSubscription?.cancel();
                _sseSubscription = null;
                _setLoading(false);
                return;
              default:
            }
          } catch (e) {
            _handleError('Error processing response', placeholderIndex,
                errorDetails: e.toString());
            // Don't automatically stop stream here unless it's fatal
          }
        },
        onError: (error, stackTrace) {
          if (streamEndedPrematurely) return; // Ignore if already finalized

          timeoutTimer.cancel();
          streamEndedPrematurely = true;
          _handleError(error, placeholderIndex);
          if (onError != null) onError(error);
          _sseSubscription = null;
          _setLoading(false);
        },
        onDone: () {
          if (streamEndedPrematurely) {
            // Check flag

            return;
          }

          timeoutTimer.cancel();
          streamEndedPrematurely = true; // Set flag
          // Call the finalization logic, passing the final accumulated text
          _finalizeResponse(
              placeholderIndex, accumulatedResponseText, currentCitations,
              onResponseContent: onResponseContent);
        },
      );
    } catch (e) {
      timeoutTimer.cancel();
      streamEndedPrematurely = true;
      _handleError('Failed to initiate stream: $e', placeholderIndex);
      if (onError != null) onError(e);
      _sseSubscription = null;
      _setLoading(false);
    }
  }

  // ... (_setLoading, _updateMessage, _handleError, _addMessage, addDirectMessage, clearMessages, dispose methods remain the same) ...
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _updateMessage(
      int index, ChatMessage Function(ChatMessage oldMessage) updateFn) {
    if (index >= 0 && index < _messages.length) {
      final oldMessage = _messages[index];
      _messages[index] = updateFn(oldMessage);

      notifyListeners();
    } else {}
  }

  void _handleError(dynamic error, int messageIndex, {String? errorDetails}) {
    String errorMessage = 'An unexpected error occurred.';
    if (error is String) {
      errorMessage = error;
    } else if (error is PlatformException) {
      errorMessage = error.message ?? 'Platform error';
      errorDetails = error.details?.toString() ?? errorDetails;
    } else if (error is Exception) {
      errorMessage = error.toString();
    }
    final fullErrorMessage =
        'Error: $errorMessage${errorDetails != null ? '\nDetails: $errorDetails' : ''}';
    _updateMessage(messageIndex, (msg) {
      return msg.copyWith(
          message: fullErrorMessage,
          isWaiting: false,
          type: 'error',
          clearCitations: true);
    });
    if (!(messageIndex >= 0 && messageIndex < _messages.length)) {
      _addMessage(ChatMessage(
          message: fullErrorMessage,
          isUser: false,
          timestamp: DateTime.now(),
          type: 'error'));
    }
    _setLoading(false);
  }

  void _addMessage(ChatMessage message) {
    _messages.add(message);

    notifyListeners();
  }

  void addDirectMessage(ChatMessage message) {
    final defaultedMessage =
        message.copyWith(timestamp: message.timestamp ?? DateTime.now());
    _messages.add(defaultedMessage);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _currentThreadId = null;
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _setLoading(false);
    notifyListeners();
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _plugin.dispose();
    super.dispose();
  }
}
