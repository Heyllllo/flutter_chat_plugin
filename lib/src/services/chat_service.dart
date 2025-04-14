// lib/src/services/chat_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
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
    print('ChatService: Initializing...');
    _setLoading(false);
    await _sseSubscription?.cancel();
    _sseSubscription = null;
    _messages.clear();
    _currentThreadId = null;
    try {
      await _plugin.initialize(domain: domain, chatbotId: chatbotId);
      print('ChatService: Initialization complete.');
      notifyListeners();
    } catch (e) {
      print('ChatService: Initialization failed: $e');
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
      print("ChatService: Already processing...");
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
      print(
          "ChatService [sendMessage]: Added user message: ${userMessage.message}");

      final placeholderIndex = _messages.length;
      final placeholderMessage = ChatMessage(
          message: '',
          isUser: false,
          isWaiting: true,
          timestamp: DateTime.now(),
          type: 'content');
      _addMessage(placeholderMessage);
      print(
          "ChatService [sendMessage]: Added placeholder at index $placeholderIndex (isWaiting=${placeholderMessage.isWaiting})");

      await _sseSubscription?.cancel();
      _sseSubscription = null;
      print("ChatService [sendMessage]: Cancelled previous subscription.");
      print(
          'ChatService [sendMessage]: Sending message: "$trimmedMessage" with threadId: $_currentThreadId');
      _streamResponse(
          message: trimmedMessage,
          threadId: _currentThreadId,
          placeholderIndex: placeholderIndex,
          onResponseContent: onResponseContent,
          onCitationsReceived: onCitationsReceived,
          onThreadIdReceived: onThreadIdReceived,
          onError: onError);
    } catch (e, stackTrace) {
      print('ChatService [sendMessage]: Error: $e\n$stackTrace');
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
    print(
        "ChatService [_finalizeResponse]: Finalizing for index $placeholderIndex.");
    // Update the message, ensuring isWaiting is false
    _updateMessage(placeholderIndex, (msg) {
      final finalType = msg.type == 'error'
          ? 'error'
          : 'content'; // Keep error type if it was set
      final finalMessage =
          accumulatedText.isNotEmpty ? accumulatedText : msg.message;
      print(
          'ChatService [_finalizeResponse]: Final state for index $placeholderIndex - isWaiting: false, type: $finalType, msgLen: ${finalMessage.length}');
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
      print(
          'ChatService [_finalizeResponse]: Removing empty message at index $placeholderIndex.');
      // Be careful modifying list while iterating or using index directly after removal
      // It's safer to remove *after* potential UI updates using this index are done, or use other logic.
      // For simplicity here, we assume removal is okay. Consider marking for removal if issues arise.
      _messages.removeAt(placeholderIndex);
      notifyListeners(); // Notify about removal
    }

    // Trigger final response callback *after* message state is updated
    if (onResponseContent != null && accumulatedText.isNotEmpty) {
      print(
          "ChatService [_finalizeResponse]: Calling onResponseContent callback.");
      onResponseContent(accumulatedText);
    }

    _sseSubscription = null; // Clear subscription ref
    _setLoading(false); // Set overall loading false
    print(
        'ChatService [_finalizeResponse]: Finished processing for index $placeholderIndex. isLoading=$_isLoading');
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
    print(
        "ChatService [_streamResponse]: Starting for index $placeholderIndex");
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
            print(
                "ChatService [_streamResponse][onData]: Received FIRST data for index $placeholderIndex");
            receivedData = true;
            timeoutTimer?.cancel();
          }

          if (kDebugMode)
            print(
                'ChatService [_streamResponse][onData]: Data for index $placeholderIndex: $data');

          final type = data['type'] as String?;

          try {
            switch (type) {
              // *** HANDLE STREAM_END EVENT HERE ***
              case 'stream_end':
                print(
                    "ChatService [_streamResponse][onData]: Received stream_end event for index $placeholderIndex. Finalizing.");
                timeoutTimer?.cancel(); // Cancel timer
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
                  print('ChatService: Updated thread_id: $newThreadId');
                  _currentThreadId = newThreadId;
                  if (onThreadIdReceived != null)
                    onThreadIdReceived(newThreadId);
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
                    if (onCitationsReceived != null)
                      onCitationsReceived(currentCitations);
                  }
                }
                break;
              case 'error':
                final errorMessage =
                    data['message'] as String? ?? 'Unknown server error';
                print(
                    'ChatService [_streamResponse][onData]: Received ERROR for index $placeholderIndex: $errorMessage');
                timeoutTimer?.cancel();
                streamEndedPrematurely = true;
                _handleError(errorMessage, placeholderIndex,
                    errorDetails: data['error_details'] as String?);
                if (onError != null) onError(errorMessage);
                _sseSubscription?.cancel();
                _sseSubscription = null;
                _setLoading(false);
                return;
              default:
                print(
                    'ChatService [_streamResponse][onData]: Received unhandled type for index $placeholderIndex: $type');
            }
          } catch (e, stackTrace) {
            print(
                'ChatService [_streamResponse][onData]: Error processing chunk for index $placeholderIndex ($type): $e\n$stackTrace');
            _handleError('Error processing response', placeholderIndex,
                errorDetails: e.toString());
            // Don't automatically stop stream here unless it's fatal
          }
        },
        onError: (error, stackTrace) {
          if (streamEndedPrematurely) return; // Ignore if already finalized
          print(
              'ChatService [_streamResponse][onError]: Stream ERROR for index $placeholderIndex: $error');
          timeoutTimer?.cancel();
          streamEndedPrematurely = true;
          _handleError(error, placeholderIndex);
          if (onError != null) onError(error);
          _sseSubscription = null;
          _setLoading(false);
        },
        onDone: () {
          if (streamEndedPrematurely) {
            // Check flag
            print(
                'ChatService [_streamResponse][onDone]: Stream ended but already finalized (likely via stream_end event) for index $placeholderIndex.');
            return;
          }
          print(
              'ChatService [_streamResponse][onDone]: Standard stream DONE for index $placeholderIndex. Finalizing.');
          timeoutTimer?.cancel();
          streamEndedPrematurely = true; // Set flag
          // Call the finalization logic, passing the final accumulated text
          _finalizeResponse(
              placeholderIndex, accumulatedResponseText, currentCitations,
              onResponseContent: onResponseContent);
        },
      );
    } catch (e, stackTrace) {
      print(
          'ChatService [_streamResponse]: Error calling plugin.streamResponse for index $placeholderIndex: $e\n$stackTrace');
      timeoutTimer?.cancel();
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
      print("ChatService [_setLoading]: Setting isLoading to $loading");
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _updateMessage(
      int index, ChatMessage Function(ChatMessage oldMessage) updateFn) {
    if (index >= 0 && index < _messages.length) {
      final oldMessage = _messages[index];
      _messages[index] = updateFn(oldMessage);
      print(
          "ChatService [_updateMessage]: Updated index $index. New isWaiting=${_messages[index].isWaiting}");
      notifyListeners();
    } else {
      print('ChatService [_updateMessage]: WARNING - Invalid index $index');
    }
  }

  void _handleError(dynamic error, int messageIndex, {String? errorDetails}) {
    print(
        'ChatService [_handleError]: Handling error for index $messageIndex: $error');
    String errorMessage = 'An unexpected error occurred.';
    if (error is String) {
      errorMessage = error;
    } else if (error is PlatformException) {
      errorMessage = error.message ?? 'Platform error';
      errorDetails = error.details?.toString() ?? errorDetails;
    } else if (error is Exception) {
      errorMessage = error.toString();
    }
    final fullErrorMessage = 'Error: $errorMessage' +
        (errorDetails != null ? '\nDetails: $errorDetails' : '');
    _updateMessage(messageIndex, (msg) {
      print(
          'ChatService [_handleError]: Updating index $messageIndex to error state, setting isWaiting=false');
      return msg.copyWith(
          message: fullErrorMessage,
          isWaiting: false,
          type: 'error',
          clearCitations: true);
    });
    if (!(messageIndex >= 0 && messageIndex < _messages.length)) {
      print(
          'ChatService [_handleError]: Invalid index $messageIndex, adding new error message.');
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
    print(
        "ChatService [_addMessage]: Added message. Total: ${_messages.length}. Notifying.");
    notifyListeners();
  }

  void addDirectMessage(ChatMessage message) {
    final defaultedMessage =
        message.copyWith(timestamp: message.timestamp ?? DateTime.now());
    _messages.add(defaultedMessage);
    notifyListeners();
  }

  void clearMessages() {
    print('ChatService: Clearing messages...');
    _messages.clear();
    _currentThreadId = null;
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _setLoading(false);
    notifyListeners();
  }

  @override
  void dispose() {
    print('ChatService: Disposing...');
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _plugin.dispose();
    print('ChatService: Dispose complete.');
    super.dispose();
  }
}
