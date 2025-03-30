// lib/chat_plugin.dart
import 'chat_plugin_platform_interface.dart';

// Export all public components
export 'src/widgets/chat_widget.dart';
export 'src/widgets/chat_bubble.dart';
export 'src/models/chat_message.dart';
export 'src/models/chat_config.dart';
export 'src/models/chat_theme.dart';
export 'src/services/chat_service.dart';

class ChatPlugin {
  Future<void> initialize({
    required String domain,
    required String chatbotId,
  }) {
    return ChatPluginPlatform.instance.initialize(
      domain: domain,
      chatbotId: chatbotId,
    );
  }

  Stream<String> streamResponse({
    required String message,
  }) {
    return ChatPluginPlatform.instance.streamResponse(
      message: message,
    );
  }

  void dispose() {
    ChatPluginPlatform.instance.dispose();
  }
}
