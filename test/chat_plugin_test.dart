// test/chat_plugin_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_plugin/chat_plugin.dart';
import 'package:chat_plugin/chat_plugin_platform_interface.dart';
import 'package:chat_plugin/chat_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'chat_plugin_test.mocks.dart';

@GenerateMocks([ChatPluginPlatform])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatPlugin', () {
    late ChatPlugin chatPlugin;
    late MockChatPluginPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockChatPluginPlatform();
      ChatPluginPlatform.instance = mockPlatform;
      chatPlugin = ChatPlugin();
    });

    test('initialize', () async {
      when(mockPlatform.initialize(
        baseUrl: anyNamed('baseUrl'),
        tenantIndex: anyNamed('tenantIndex'),
      )).thenAnswer((_) => Future<void>.value());

      await chatPlugin.initialize(
        baseUrl: 'test',
        tenantIndex: 'test',
      );

      verify(mockPlatform.initialize(
        baseUrl: 'test',
        tenantIndex: 'test',
      )).called(1);
    });

    test('sendMessage', () async {
      final expectedResponse = {
        'status': 200,
        'id': 1,
        'chatBotLogId': 1,
      };

      when(mockPlatform.sendMessage(
        message: anyNamed('message'),
        chatBotLogId: anyNamed('chatBotLogId'),
      )).thenAnswer((_) async => expectedResponse);

      final result = await chatPlugin.sendMessage(
        message: 'test',
        chatBotLogId: 1,
      );

      verify(mockPlatform.sendMessage(
        message: 'test',
        chatBotLogId: 1,
      )).called(1);

      expect(result, equals(expectedResponse));
    });

    test('streamResponse', () {
      final expectedStream = Stream<String>.fromIterable(['test response']);

      when(mockPlatform.streamResponse(
        chatBotLogId: anyNamed('chatBotLogId'),
        message: anyNamed('message'),
      )).thenAnswer((_) => expectedStream);

      final stream = chatPlugin.streamResponse(
        chatBotLogId: 1,
        message: 'test',
      );

      verify(mockPlatform.streamResponse(
        chatBotLogId: 1,
        message: 'test',
      )).called(1);

      expect(stream, isA<Stream<String>>());
    });

    test('saveChatMessage', () async {
      final expectedResponse = {
        'status': 200,
        'chatBotLogMessage': {'id': 1},
      };

      when(mockPlatform.saveChatMessage(
        message: anyNamed('message'),
        chatBotLogId: anyNamed('chatBotLogId'),
        chatBotLogMessageId: anyNamed('chatBotLogMessageId'),
      )).thenAnswer((_) async => expectedResponse);

      final result = await chatPlugin.saveChatMessage(
        message: 'test',
        chatBotLogId: 1,
        chatBotLogMessageId: 1,
      );

      verify(mockPlatform.saveChatMessage(
        message: 'test',
        chatBotLogId: 1,
        chatBotLogMessageId: 1,
      )).called(1);

      expect(result, equals(expectedResponse));
    });

    test('dispose', () {
      when(mockPlatform.dispose()).thenReturn(null);

      chatPlugin.dispose();

      verify(mockPlatform.dispose()).called(1);
    });
  });
}
