import 'package:flutter_test/flutter_test.dart';
import 'package:heyllo_ai_chatbot/chat_plugin.dart'; // Assuming this path is correct
import 'package:heyllo_ai_chatbot/chat_plugin_method_channel.dart';
import 'package:heyllo_ai_chatbot/chat_plugin_platform_interface.dart';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:async'; // Import for Stream

// Mock implementation of the platform interface
class MockChatPluginPlatform
    with
        MockPlatformInterfaceMixin // Use mixin for platform interface mocks
    implements
        ChatPluginPlatform {
  // Keep track of initialize calls if needed
  bool initializedCalled = false;
  String? lastDomain;
  String? lastChatbotId;

  // Keep track of dispose calls
  bool disposeCalled = false;

  // Keep track of streamResponse calls
  bool streamResponseCalled = false;
  String? lastMessage;
  String? lastThreadId;

  @override
  Future<void> initialize({
    required String domain,
    required String chatbotId,
  }) async {
    initializedCalled = true;
    lastDomain = domain;
    lastChatbotId = chatbotId;
    print(
        "MockPlatform: initialize called (domain: $domain, chatbotId: $chatbotId)");
    // Simulate async operation
    await Future.delayed(Duration.zero);
    return;
  }

  // *** UPDATED SIGNATURE AND RETURN TYPE ***
  @override
  Stream<Map<String, dynamic>> streamResponse({
    required String message,
    String? threadId, // Accept optional threadId
  }) {
    streamResponseCalled = true;
    lastMessage = message;
    lastThreadId = threadId;
    print(
        "MockPlatform: streamResponse called (message: $message, threadId: $threadId)");
    // Return a stream emitting a sample map
    return Stream.fromIterable([
      {'type': 'content', 'text': 'Mock response for "$message"'}
    ]);
  }

  @override
  void dispose() {
    disposeCalled = true;
    print("MockPlatform: dispose called");
    return;
  }

  // Helper to reset flags between tests if needed
  void reset() {
    initializedCalled = false;
    lastDomain = null;
    lastChatbotId = null;
    disposeCalled = false;
    streamResponseCalled = false;
    lastMessage = null;
    lastThreadId = null;
  }
}

void main() {
  // Store the original instance before overriding it
  final ChatPluginPlatform initialPlatform = ChatPluginPlatform.instance;
  // Declare mock platform instance
  late MockChatPluginPlatform fakePlatform;

  // Setup before each test
  setUp(() {
    fakePlatform = MockChatPluginPlatform(); // Create a fresh mock
    ChatPluginPlatform.instance =
        fakePlatform; // Set the static instance to the mock
  });

  // Restore the original platform instance after each test
  tearDown(() {
    ChatPluginPlatform.instance = initialPlatform;
  });

  test('$MethodChannelChatPlugin is the default instance', () {
    // Test if the *initial* platform instance was the correct type
    expect(initialPlatform, isInstanceOf<MethodChannelChatPlugin>());
  });

  test('initialize: calls platform initialize', () async {
    // Arrange
    final plugin = ChatPlugin();
    const domain = 'https://mock.example';
    const chatbotId = 'mock-bot-123';

    // Act
    await plugin.initialize(domain: domain, chatbotId: chatbotId);

    // Assert
    // Verify that the mock platform's initialize method was called
    expect(fakePlatform.initializedCalled, isTrue);
    expect(fakePlatform.lastDomain, equals(domain));
    expect(fakePlatform.lastChatbotId, equals(chatbotId));
  });

  test(
      'streamResponse: calls platform streamResponse and returns correct stream type',
      () async {
    // Arrange
    final plugin = ChatPlugin();
    const message = "Hello mock";
    const threadId = "thread-mock";

    // Act
    // Call streamResponse on the plugin, which delegates to the mock platform
    final stream = plugin.streamResponse(message: message, threadId: threadId);

    // Assert
    // 1. Verify the mock platform method was called with correct arguments
    expect(fakePlatform.streamResponseCalled, isTrue);
    expect(fakePlatform.lastMessage, equals(message));
    expect(fakePlatform.lastThreadId, equals(threadId));

    // 2. Verify the returned type is correct
    expect(stream, isA<Stream<Map<String, dynamic>>>());

    // 3. Optionally, verify the content of the stream emitted by the mock
    await expectLater(
      stream,
      emits(predicate<Map<String, dynamic>>((event) {
        return event['type'] == 'content' &&
            event['text'] == 'Mock response for "$message"';
      })),
    );
    // You could add emitsDone if your mock stream closes:
    // await expectLater(stream, emitsDone);
  });

  test('dispose: calls platform dispose', () async {
    // Arrange
    final plugin = ChatPlugin();
    // Optionally initialize first
    await plugin.initialize(domain: 'd', chatbotId: 'id');
    expect(fakePlatform.disposeCalled, isFalse); // Ensure it wasn't called yet

    // Act
    plugin.dispose();

    // Assert
    expect(fakePlatform.disposeCalled, isTrue);
  });
}
