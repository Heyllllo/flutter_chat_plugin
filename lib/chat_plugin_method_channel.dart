// lib/chat_plugin_method_channel.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// Assuming flutter_client_sse is the library used
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';

import 'chat_plugin_platform_interface.dart';

/// An implementation of [ChatPluginPlatform] that uses method channels.
class MethodChannelChatPlugin extends ChatPluginPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('chat_plugin');

  String? _domain;
  String? _chatbotId;
  StreamController<SSEModel>? _streamController;

  // ... (initialize method remains the same) ...
  @override
  Future<void> initialize({
    required String domain,
    required String chatbotId,
  }) async {
    _domain = domain;
    _chatbotId = chatbotId;
    print(
        '📡 Chat Plugin Initialized (Method Channel): Domain=$_domain, ChatbotId=$_chatbotId');
    await _streamController?.close();
    _streamController = null;
    SSEClient.unsubscribeFromSSE();
  }

  @override
  Stream<Map<String, dynamic>> streamResponse({
    required String message,
    String? threadId,
  }) {
    if (_domain == null || _chatbotId == null) {
      final error = ArgumentError(
          'ChatPlugin must be initialized before calling streamResponse.');
      print('📡 Chat Plugin Error: ${error.message}');
      return Stream.value({
        'type': 'error',
        'message': 'Initialization required.',
        'error_details': error.toString(),
      });
    }

    try {
      print('📡 Chat Plugin: Preparing request');
      final queryParams = {'query': message};
      if (threadId != null && threadId.isNotEmpty) {
        queryParams['thread_id'] = threadId;
        print('📡 Chat Plugin: Sending with thread_id: $threadId');
      }
      final sseUrl = Uri.parse('$_domain/api/chat/$_chatbotId')
          .replace(queryParameters: queryParams);
      print('📡 Chat Plugin: Connecting to SSE URL: $sseUrl');

      _streamController?.close();
      _streamController = StreamController<SSEModel>();

      final loggingTransformer =
          StreamTransformer<SSEModel, SSEModel>.fromHandlers(
              /* ... logging logic ... */);

      // *** UPDATED TRANSFORMER ***
      final transformer =
          StreamTransformer<SSEModel, Map<String, dynamic>>.fromHandlers(
              handleData:
                  (SSEModel event, EventSink<Map<String, dynamic>> sink) {
        if (kDebugMode)
          print(
              '📡 Chat Plugin [PROCESS]: Processing event: "${event.event}", data: ${event.data}');

        // --- Handle specific backend event for stream end ---
        if (event.event == 'stream_end') {
          print(
              '📡 Chat Plugin [PROCESS]: Detected stream_end event. Emitting specific type.');
          sink.add(
              {'type': 'stream_end'}); // Emit a specific map for this event
          return; // Stop further processing for this event
        }
        // --- End stream_end handling ---

        // Process regular data events
        if (event.data != null && event.data!.isNotEmpty) {
          try {
            final String cleanData = event.data!.trim();
            if (cleanData.isEmpty) return;

            final Map<String, dynamic> jsonData = jsonDecode(cleanData);
            final type = jsonData['type'] as String?;

            if (type == null || type.isEmpty) {
              print(
                  '📡 Chat Plugin [WARN]: Received data chunk without a "type" field: $cleanData');
              return;
            }

            const validTypes = {
              'content',
              'metadata',
              'citations',
              'error'
            }; // Removed 'stream-done' if not used
            if (!validTypes.contains(type)) {
              print(
                  '📡 Chat Plugin [WARN]: Received unknown data type "$type": $cleanData');
            }

            if (kDebugMode)
              print('📡 Chat Plugin [EMIT]: Parsed JSON: $jsonData');
            sink.add(jsonData);
          } on FormatException catch (e) {
            print(
                '📡 Chat Plugin [ERROR]: Failed to parse JSON: "${event.data}" - Error: $e');
            sink.add({
              'type': 'error',
              'message': 'Received non-JSON data.',
              'raw_data': event.data,
              'error_details': e.toString()
            });
          } catch (e, stackTrace) {
            print(
                '📡 Chat Plugin [ERROR]: Unexpected error processing data: $e\n$stackTrace');
            sink.add({
              'type': 'error',
              'message': 'Internal processing error.',
              'raw_data': event.data,
              'error_details': e.toString()
            });
          }
        } else {
          // Log other non-data or non-stream_end events if needed
          if (kDebugMode && (event.event != null && event.event!.isNotEmpty)) {
            print(
                '📡 Chat Plugin [PROCESS]: Received unhandled named event: "${event.event}", data: ${event.data}');
          }
        }
      }, handleError: (error, stackTrace, sink) {
        print('📡 Chat Plugin [TRANSFORM ERROR]: Propagating error: $error');
        sink.add({
          'type': 'error',
          'message': 'Connection error.',
          'error_details': error.toString()
        });
      }, handleDone: (sink) {
        print(
            '📡 Chat Plugin [TRANSFORM DONE]: Source stream closed. Closing transformer.');
        sink.close();
      });

      print('📡 Chat Plugin: Subscribing to SSE stream...');
      final stream = SSEClient.subscribeToSSE(
        method: SSERequestType.GET,
        url: sseUrl.toString(),
        header: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
        oldStreamController: _streamController,
      );

      print('📡 Chat Plugin: SSE subscription initiated.');
      return stream
          .transform(kDebugMode
              ? loggingTransformer
              : StreamTransformer.fromHandlers())
          .transform(transformer)
          .handleError((error) {
        print('📡 Chat Plugin [FINAL ERROR]: $error');
      });
    } catch (e, stackTrace) {
      print('📡 Chat Plugin [SETUP ERROR]: $e\n$stackTrace');
      return Stream.value({
        'type': 'error',
        'message': 'Failed to setup connection.',
        'error_details': e.toString()
      }).asBroadcastStream();
    }
  }

  // ... (dispose method remains the same) ...
  @override
  void dispose() {
    print('📡 Chat Plugin: Disposing MethodChannelChatPlugin...');
    SSEClient.unsubscribeFromSSE();
    _streamController?.close();
    _streamController = null;
    _domain = null;
    _chatbotId = null;
    print('📡 Chat Plugin: Dispose complete.');
  }
}
