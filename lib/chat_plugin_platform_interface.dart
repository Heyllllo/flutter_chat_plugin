// lib/chat_plugin_platform_interface.dart
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'chat_plugin_method_channel.dart';

abstract class ChatPluginPlatform extends PlatformInterface {
  ChatPluginPlatform() : super(token: _token);

  static final Object _token = Object();
  static ChatPluginPlatform _instance = MethodChannelChatPlugin();

  static ChatPluginPlatform get instance => _instance;

  static set instance(ChatPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize({
    required String domain,
    required String chatbotId,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Stream<String> streamResponse({
    required String message,
  }) {
    throw UnimplementedError('streamResponse() has not been implemented.');
  }

  void dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
