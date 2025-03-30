import 'package:flutter_test/flutter_test.dart';
import 'package:chat_plugin/chat_plugin.dart';
import 'package:chat_plugin/chat_plugin_platform_interface.dart';
import 'package:chat_plugin/chat_plugin_method_channel.dart';
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
    await plugin.initialize(domain: 'https://example.com', chatbotId: 'test-bot');
  });

  test('streamResponse', () {
    MockChatPluginPlatform fakePlatform = MockChatPluginPlatform();
    ChatPluginPlatform.instance = fakePlatform;
    
    final plugin = ChatPlugin();
    final stream = plugin.streamResponse(message: 'Hello');
    
    expect(stream, isA<Stream<String>>());
  });
}