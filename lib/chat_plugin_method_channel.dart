// lib/chat_plugin_method_channel.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'chat_plugin_platform_interface.dart';

class MethodChannelChatPlugin extends ChatPluginPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('chat_plugin');

  String? _baseUrl;
  String? _tenantIndex;
  StreamController<SSEModel>? _streamController;

  @override
  Future<void> initialize({
    required String baseUrl,
    required String tenantIndex,
  }) async {
    _baseUrl = baseUrl;
    _tenantIndex = tenantIndex;
  }

  @override
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    int? chatBotLogId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chatbots/message'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tenantIndex': _tenantIndex,
          'chatBotLogId': chatBotLogId,
          'message': message,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send message: ${response.statusCode}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Error sending message: $e');
    }
  }

  @override
  Stream<String> streamResponse({
    required int chatBotLogId,
    required String message,
  }) {
    try {
      // Create a transformer to convert SSEModel to String
      final transformer = StreamTransformer<SSEModel, String>.fromHandlers(
        handleData: (SSEModel event, EventSink<String> sink) {
          if (event.event == 'message' && event.data != null) {
            final data = jsonDecode(event.data!);
            sink.add(data['text'] as String);
          }
        },
      );

      final sseUrl = Uri.parse('$_baseUrl/chat/$_tenantIndex').replace(
        queryParameters: {
          'log_id': chatBotLogId.toString(),
          'query': message,
        },
      );

      // Cleanup any existing stream
      _streamController?.close();
      _streamController = StreamController<SSEModel>();

      // Subscribe to SSE
      final stream = SSEClient.subscribeToSSE(
        method: SSERequestType.GET,
        url: sseUrl.toString(),
        header: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
        oldStreamController: _streamController,
      );

      // Transform and return the stream
      return stream.transform(transformer);
    } catch (e) {
      print('Error establishing SSE connection: $e');
      throw Exception('Error establishing SSE connection: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> saveChatMessage({
    required String message,
    required int chatBotLogId,
    int? chatBotLogMessageId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chatbots/log'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chatBotLogId': chatBotLogId,
          'chatBotLogMessageId': chatBotLogMessageId,
          'message': message,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save message');
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Error saving message: $e');
      throw Exception('Error saving message: $e');
    }
  }

  @override
  void dispose() {
    // Cleanup SSE connection
    SSEClient.unsubscribeFromSSE();
    _streamController?.close();
    _streamController = null;
  }
}
