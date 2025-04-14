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

      return Stream.value({
        'type': 'error',
        'message': 'Initialization required.',
        'error_details': error.toString(),
      });
    }

    try {
      final queryParams = {'query': message};
      if (threadId != null && threadId.isNotEmpty) {
        queryParams['thread_id'] = threadId;
      }
      final sseUrl = Uri.parse('$_domain/api/chat/$_chatbotId')
          .replace(queryParameters: queryParams);

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
        // --- Handle specific backend event for stream end ---
        if (event.event == 'stream_end') {
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
              return;
            }

            const validTypes = {
              'content',
              'metadata',
              'citations',
              'error'
            }; // Removed 'stream-done' if not used
            if (!validTypes.contains(type)) {}

            if (kDebugMode) sink.add(jsonData);
          } on FormatException catch (e) {
            sink.add({
              'type': 'error',
              'message': 'Received non-JSON data.',
              'raw_data': event.data,
              'error_details': e.toString()
            });
          } catch (e) {
            sink.add({
              'type': 'error',
              'message': 'Internal processing error.',
              'raw_data': event.data,
              'error_details': e.toString()
            });
          }
        } else {
          // Log other non-data or non-stream_end events if needed
          if (kDebugMode && (event.event != null && event.event!.isNotEmpty)) {}
        }
      }, handleError: (error, stackTrace, sink) {
        sink.add({
          'type': 'error',
          'message': 'Connection error.',
          'error_details': error.toString()
        });
      }, handleDone: (sink) {
        sink.close();
      });

      final stream = SSEClient.subscribeToSSE(
        method: SSERequestType.GET,
        url: sseUrl.toString(),
        header: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
        oldStreamController: _streamController,
      );

      return stream
          .transform(kDebugMode
              ? loggingTransformer
              : StreamTransformer.fromHandlers())
          .transform(transformer)
          .handleError((error) {});
    } catch (e) {
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
    SSEClient.unsubscribeFromSSE();
    _streamController?.close();
    _streamController = null;
    _domain = null;
    _chatbotId = null;
  }
}
