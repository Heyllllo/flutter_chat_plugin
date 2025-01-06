// lib/chat_plugin.dart
import 'chat_plugin_platform_interface.dart';
export 'src/widgets/chat_widget.dart';
export 'src/models/chat_message.dart';
export 'src/models/chat_config.dart';

class ChatPlugin {
  Future<void> initialize({
    required String baseUrl,
    required String tenantIndex,
  }) {
    return ChatPluginPlatform.instance.initialize(
      baseUrl: baseUrl,
      tenantIndex: tenantIndex,
    );
  }

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    int? chatBotLogId,
  }) {
    return ChatPluginPlatform.instance.sendMessage(
      message: message,
      chatBotLogId: chatBotLogId,
    );
  }

  Stream<String> streamResponse({
    required int chatBotLogId,
    required String message,
  }) {
    return ChatPluginPlatform.instance.streamResponse(
      chatBotLogId: chatBotLogId,
      message: message,
    );
  }

  Future<Map<String, dynamic>> saveChatMessage({
    required String message,
    required int chatBotLogId,
    int? chatBotLogMessageId,
  }) {
    return ChatPluginPlatform.instance.saveChatMessage(
      message: message,
      chatBotLogId: chatBotLogId,
      chatBotLogMessageId: chatBotLogMessageId,
    );
  }

  void dispose() {
    ChatPluginPlatform.instance.dispose();
  }
}
