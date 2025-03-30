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

  final http.Client httpClient;
  String? _domain;
  String? _chatbotId;
  StreamController<SSEModel>? _streamController;

  MethodChannelChatPlugin({http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  @override
  Future<void> initialize({
    required String domain,
    required String chatbotId,
  }) async {
    _domain = domain;
    _chatbotId = chatbotId;
  }

// In chat_plugin_method_channel.dart
// In chat_plugin_method_channel.dart

// Add detailed logging to the streamResponse method
  @override
  Stream<String> streamResponse({
    required String message,
  }) {
    try {
      // Log the request info
      print('📡 Chat Plugin: Preparing request');

      // Construct URL: https://heyllo.co/api/chat/syihwef?query=Hi
      final sseUrl = Uri.parse('$_domain/api/chat/$_chatbotId').replace(
        queryParameters: {
          'query': message,
        },
      );

      // Log the URL being accessed
      print('📡 Chat Plugin: Connecting to SSE URL: $sseUrl');
      print(
          '📡 Chat Plugin: With headers: Accept=text/event-stream, Cache-Control=no-cache');

      // Cleanup any existing stream
      _streamController?.close();
      _streamController = StreamController<SSEModel>();

      // Create a transformer that logs everything
      final loggingTransformer =
          StreamTransformer<SSEModel, SSEModel>.fromHandlers(
        handleData: (event, sink) {
          print('📡 Chat Plugin: Received event: ${event.event}');
          print('📡 Chat Plugin: Received data: ${event.data}');
          sink.add(event);
        },
        handleError: (error, stackTrace, sink) {
          print('📡 Chat Plugin: Error in SSE stream: $error');
          print('📡 Chat Plugin: Error stacktrace: $stackTrace');
          sink.addError(error, stackTrace);
        },
        handleDone: (sink) {
          print('📡 Chat Plugin: SSE stream closed');
          sink.close();
        },
      );

      // Create the regular transformer to convert SSEModel to String
      // In chat_plugin_method_channel.dart
// Update the transformer in the streamResponse method

      final transformer = StreamTransformer<SSEModel, String>.fromHandlers(
        handleData: (SSEModel event, EventSink<String> sink) {
          // Print more detailed debug info
          print(
              '📡 Chat Plugin: Processing event: "${event.event}" with data: ${event.data}');

          // Handle data events - either empty event name or "message" event
          if ((event.event == null ||
                  event.event!.isEmpty ||
                  event.event == 'message') &&
              event.data != null) {
            try {
              // Trim whitespace before parsing JSON
              final String cleanData = event.data!.trim();
              final Map<String, dynamic> jsonData = jsonDecode(cleanData);

              if (jsonData.containsKey('error')) {
                // This is an error message, handle it as an error
                final errorMessage = jsonData['error'];
                print('📡 Chat Plugin: Server returned error: $errorMessage');
                sink.addError(
                  Exception(errorMessage),
                  StackTrace.current,
                );
                return;
              }

              if (jsonData.containsKey('text')) {
                // This is a text chunk in the expected format
                print('📡 Chat Plugin: Extracted text: "${jsonData['text']}"');
                sink.add(jsonData['text']);
                return;
              }
            } catch (e) {
              // Not JSON or couldn't parse - just treat as regular text
              print(
                  '📡 Chat Plugin: Could not parse as JSON: "${event.data}" - Error: $e');
            }

            // Default behavior - pass through the raw data
            print('📡 Chat Plugin: Using raw data: ${event.data}');
            sink.add(event.data!);
          } else if (event.event == 'stream-done') {
            // Handle the stream-done event - nothing to do, just for tracking
            print('📡 Chat Plugin: Stream done event received');
          }
        },
        handleError: (error, stackTrace, sink) {
          // Propagate errors through the stream
          print('📡 Chat Plugin: Error in transformer: $error');
          sink.addError(error, stackTrace);
        },
      );
      print('📡 Chat Plugin: Subscribing to SSE stream');

      // Subscribe to SSE with logging
      final stream = SSEClient.subscribeToSSE(
        method: SSERequestType.GET,
        url: sseUrl.toString(),
        header: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
        oldStreamController: _streamController,
      );

      print('📡 Chat Plugin: SSE subscription created, waiting for events...');

      // Transform with logging first, then with the regular transformer
      return stream.transform(loggingTransformer).transform(transformer);
    } catch (e) {
      print('📡 Chat Plugin: Error establishing SSE connection: $e');
      return Stream<String>.error(
        Exception('Error establishing SSE connection: $e'),
        StackTrace.current,
      );
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

// A simple HTTP logging interceptor
class LoggingInterceptor extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Log request details
    print('📡 HTTP: ${request.method} ${request.url}');
    print('📡 HTTP: Headers: ${request.headers}');

    // Send the request
    final response = await _inner.send(request);

    // Log response details
    print('📡 HTTP: Response status: ${response.statusCode}');
    print('📡 HTTP: Response headers: ${response.headers}');

    return response;
  }

  @override
  void close() {
    _inner.close();
  }
}
