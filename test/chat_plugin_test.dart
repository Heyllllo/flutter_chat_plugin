import 'package:flutter_test/flutter_test.dart';
import 'package:heyllo_ai_chatbot/chat_plugin.dart';
import 'package:heyllo_ai_chatbot/chat_plugin_method_channel.dart';
import 'package:heyllo_ai_chatbot/chat_plugin_platform_interface.dart';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockChatPluginPlatform
    with MockPlatformInterfaceMixin
    implements ChatPluginPlatform {
  @override
  Future<void> initialize({
    required String domain,
    required String chatbotId,
  }) async {
    return;
  }

  @override
  Stream<String> streamResponse({
    required String message,
  }) {
    return Stream.value('Test response');
  }

  @override
  void dispose() {
    return;
  }
}

void main() {
  final ChatPluginPlatform initialPlatform = ChatPluginPlatform.instance;

  test('$MethodChannelChatPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelChatPlugin>());
  });

  test('initialize', () async {
    MockChatPluginPlatform fakePlatform = MockChatPluginPlatform();
    ChatPluginPlatform.instance = fakePlatform;

    final plugin = ChatPlugin();
    await plugin.initialize(
        domain: 'https://example.com', chatbotId: 'test-bot');
  });

  test('streamResponse', () {
    MockChatPluginPlatform fakePlatform = MockChatPluginPlatform();
    ChatPluginPlatform.instance = fakePlatform;

    final plugin = ChatPlugin();
    final stream = plugin.streamResponse(message: 'Hello');

    expect(stream, isA<Stream<String>>());
  });
}
