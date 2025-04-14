// lib/chat_plugin_platform_interface.dart
import 'dart:async'; // Ensure async is imported for Stream

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'chat_plugin_method_channel.dart'; // Import the default implementation

/// The interface that implementations of chat_plugin must implement.
///
/// Platform implementations should extend this class rather than implement it as `chat_plugin`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [ChatPluginPlatform] methods.
abstract class ChatPluginPlatform extends PlatformInterface {
  /// Constructs a ChatPluginPlatform.
  ChatPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static ChatPluginPlatform _instance = MethodChannelChatPlugin();

  /// The default instance of [ChatPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelChatPlugin].
  static ChatPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ChatPluginPlatform] when
  /// they register themselves.
  static set instance(ChatPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initializes the chat plugin with the necessary configuration.
  ///
  /// Must be called before `streamResponse`.
  Future<void> initialize({
    required String domain,
    required String chatbotId,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Sends a message and returns a stream of structured responses from the backend.
  ///
  /// The stream emits `Map<String, dynamic>` objects representing parsed JSON
  /// data chunks received via Server-Sent Events (SSE).
  ///
  /// Requires [initialize] to have been called successfully.
  /// The [threadId] can be passed to maintain conversation context if supported by the backend.
  Stream<Map<String, dynamic>> streamResponse({
    required String message,
    String? threadId, // Add threadId for context
  }) {
    throw UnimplementedError('streamResponse() has not been implemented.');
  }

  /// Cleans up resources used by the plugin.
  ///
  /// Should be called when the chat functionality is no longer needed,
  /// e.g., in the `dispose` method of a widget state.
  void dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
