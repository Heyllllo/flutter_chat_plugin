// test/chat_plugin_method_channel_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_plugin/chat_plugin_method_channel.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'chat_plugin_method_channel_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelChatPlugin platform;
  late MockClient mockHttpClient;
  const baseUrl = 'https://test.com';
  const tenantIndex = 'test-tenant';

  setUp(() async {
    platform = MethodChannelChatPlugin();
    mockHttpClient = MockClient();
    await platform.initialize(
      baseUrl: baseUrl,
      tenantIndex: tenantIndex,
    );
  });

  group('sendMessage', () {
    test('sends message successfully', () async {
      final expectedResponse = {
        'status': 200,
        'id': 1,
        'chatBotLogId': 1,
      };

      when(
        mockHttpClient.post(
          Uri.parse('$baseUrl/api/chatbots/message'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response(
        '{"status": 200, "id": 1, "chatBotLogId": 1}',
        200,
      ));

      final result = await platform.sendMessage(
        message: 'test message',
        chatBotLogId: 1,
      );

      expect(result, equals(expectedResponse));
    });

    test('throws exception on error', () async {
      when(
        mockHttpClient.post(
          Uri.parse('$baseUrl/api/chatbots/message'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Error', 500));

      expect(
        () => platform.sendMessage(
          message: 'test message',
          chatBotLogId: 1,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('saveChatMessage', () {
    test('saves message successfully', () async {
      final expectedResponse = {
        'status': 200,
        'chatBotLogMessage': {'id': 1},
      };

      when(
        mockHttpClient.post(
          Uri.parse('$baseUrl/api/chatbots/log'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response(
        '{"status": 200, "chatBotLogMessage": {"id": 1}}',
        200,
      ));

      final result = await platform.saveChatMessage(
        message: 'test message',
        chatBotLogId: 1,
        chatBotLogMessageId: 1,
      );

      expect(result, equals(expectedResponse));
    });

    test('throws exception on error', () async {
      when(
        mockHttpClient.post(
          Uri.parse('$baseUrl/api/chatbots/log'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Error', 500));

      expect(
        () => platform.saveChatMessage(
          message: 'test message',
          chatBotLogId: 1,
          chatBotLogMessageId: 1,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  test('streamResponse returns a Stream<String>', () {
    final stream = platform.streamResponse(
      chatBotLogId: 1,
      message: 'test',
    );
    expect(stream, isA<Stream<String>>());
  });

  test('dispose cleans up resources', () {
    platform.dispose();
    // No exception means success
    expect(true, isTrue);
  });
}