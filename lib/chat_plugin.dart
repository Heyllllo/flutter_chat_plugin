// lib/chat_plugin.dart

// Main entry point for using the plugin.
// This class delegates calls to the platform-specific implementation.

import 'dart:async'; // For Stream

import 'chat_plugin_platform_interface.dart';

// Export necessary components for easy use by consumers of the plugin
export 'src/widgets/chat_widget.dart';
export 'src/widgets/chat_bubble.dart';
export 'src/models/chat_message.dart';
export 'src/models/chat_config.dart'; // Keep if ChatConfig is used externally
export 'src/models/chat_theme.dart';
export 'src/services/chat_service.dart'; // Export if service needs direct access (less common)
export 'src/widgets/typing_indicator.dart'; // Export if used externally

/// The main class for interacting with the Chat Plugin.
///
/// Provides methods to initialize the connection, send messages,
/// and receive streamed responses.
class ChatPlugin {
  // Flag to track initialization status internally (optional)
  // bool _isInitialized = false;

  /// Initializes the chat plugin with the backend domain and chatbot ID.
  ///
  /// This must be called before sending messages.
  Future<void> initialize({
    required String domain,
    required String chatbotId,
  }) async {
    await ChatPluginPlatform.instance.initialize(
      domain: domain,
      chatbotId: chatbotId,
    );
    // _isInitialized = true;
  }

  /// Sends a message to the chatbot and returns a stream of responses.
  ///
  /// Each item in the stream is a `Map<String, dynamic>` representing a
  /// structured message part received from the backend (e.g., content, metadata, citations).
  ///
  /// Optionally include the [threadId] to provide conversation context.
  Stream<Map<String, dynamic>> streamResponse({
    required String message,
    String? threadId, // Pass threadId for context
  }) {
    // Optional: Check initialization status before proceeding
    // if (!_isInitialized) {
    //   return Stream.error(StateError("ChatPlugin not initialized. Call initialize() first."));
    // }
    return ChatPluginPlatform.instance.streamResponse(
      message: message,
      threadId: threadId, // Pass threadId to the platform implementation
    );
  }

  /// Disposes of resources used by the plugin, such as active SSE connections.
  ///
  /// Call this when the chat functionality is no longer needed to prevent memory leaks.
  void dispose() {
    // _isInitialized = false; // Reset status on dispose
    ChatPluginPlatform.instance.dispose();
  }

  // --- Optional Enable/Disable Logic ---
  // If you want global enable/disable managed here instead of just in the widget:
  //
  // bool _isEnabled = true;
  // bool get isEnabled => _isEnabled;
  // String? _cachedDomain;
  // String? _cachedChatbotId;

  // Future<void> initialize({required String domain, required String chatbotId}) async {
  //   _cachedDomain = domain;
  //   _cachedChatbotId = chatbotId;
  //   if (_isEnabled) { // Only initialize if enabled
  //      await ChatPluginPlatform.instance.initialize(domain: domain, chatbotId: chatbotId);
  //      _isInitialized = true;
  //   } else {
  //      _isInitialized = false;
  //   }
  // }

  // Stream<Map<String, dynamic>> streamResponse({required String message, String? threadId}) {
  //    if (!_isEnabled || !_isInitialized) {
  //       return Stream.value({
  //         'type': 'error',
  //         'message': !_isEnabled ? 'Chat plugin is disabled.' : 'Chat plugin not initialized.',
  //       });
  //    }
  //    return ChatPluginPlatform.instance.streamResponse(message: message, threadId: threadId);
  // }

  // void disable() {
  //    if (_isEnabled) {
  //       print("Disabling ChatPlugin...");
  //       _isEnabled = false;
  //       dispose(); // Dispose resources when disabling
  //       _isInitialized = false;
  //    }
  // }

  // Future<void> enable() async {
  //    if (!_isEnabled) {
  //       print("Enabling ChatPlugin...");
  //       _isEnabled = true;
  //       if (_cachedDomain != null && _cachedChatbotId != null) {
  //          // Re-initialize with cached config if available
  //          await initialize(domain: _cachedDomain!, chatbotId: _cachedChatbotId!);
  //       } else {
  //          print("Warning: ChatPlugin enabled but no configuration cached. Call initialize() again.");
  //          _isInitialized = false; // Mark as not initialized until initialize is called
  //       }
  //    }
  // }

  // void dispose() {
  //   _isInitialized = false;
  //   ChatPluginPlatform.instance.dispose();
  // }
  // --- End Optional Enable/Disable Logic ---
}
