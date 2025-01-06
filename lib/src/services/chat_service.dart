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
    required String baseUrl,
    required String tenantIndex,
  }) async {
    await _plugin.initialize(
      baseUrl: baseUrl,
      tenantIndex: tenantIndex,
    );
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Send initial message
      final response = await _plugin.sendMessage(
        message: message,
        chatBotLogId: _messages.isNotEmpty ? _messages.last.chatLogId : null,
      );

      if (response['status'] == 200) {
        // Add user message
        _addMessage(ChatMessage(
          id: response['id'] ?? 0,
          message: message,
          isUser: true,
          chatLogId: response['chatBotLogId'],
        ));

        // Create placeholder for AI response
        final placeholder = await _plugin.saveChatMessage(
          message: '',
          chatBotLogId: response['chatBotLogId'],
        );

        if (placeholder['status'] == 200) {
          final placeholderMessage = ChatMessage(
            id: placeholder['chatBotLogMessage']['id'],
            message: '',
            isUser: false,
            chatLogId: response['chatBotLogId'],
            isWaiting: true,
          );
          _addMessage(placeholderMessage);

          // Start streaming response
          _streamResponse(
            chatBotLogId: response['chatBotLogId'],
            message: message,
            messageId: placeholderMessage.id,
          );
        }
      }
    } catch (e) {
      print('Error in sendMessage: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _streamResponse({
    required int chatBotLogId,
    required String message,
    required int messageId,
  }) {
    _sseSubscription?.cancel();

    _sseSubscription = _plugin
        .streamResponse(
      chatBotLogId: chatBotLogId,
      message: message,
    )
        .listen(
      (response) {
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: messageId,
            message: response,
            isUser: false,
            chatLogId: chatBotLogId,
            isWaiting: false,
          );
          notifyListeners();
        }
      },
      onError: (error) {
        print('Error in streamResponse: $error');
      },
      onDone: () {
        _sseSubscription = null;
      },
    );
  }

  void _addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _plugin.dispose();
    super.dispose();
  }
}
