// example/integration_test/plugin_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heyllo_ai_chatbot/chat_plugin.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chat_plugin_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test full chat flow', (tester) async {
    // Start app
    app.main();
    await tester.pumpAndSettle();

    // Verify the chat interface is shown
    expect(find.byType(ChatWidget), findsOneWidget);

    // Find the text input field
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Type a message
    await tester.enterText(textField, 'Hello, this is a test message');
    await tester.pumpAndSettle();

    // Find and tap the send button
    final sendButton = find.byIcon(Icons.send);
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    // Verify message was sent (should appear in the list)
    expect(find.text('Hello, this is a test message'), findsOneWidget);

    // Wait for response (adjust timeout as needed)
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Verify loading indicators behave correctly
    final loadingIndicator = find.byType(CircularProgressIndicator);
    expect(loadingIndicator, findsNothing); // Should be gone after response
  });

  testWidgets('Test error handling', (tester) async {
    // Initialize with invalid URL to test error handling
    final chatPlugin = ChatPlugin();

    await tester.runAsync(() async {
      try {
        await chatPlugin.initialize(
          domain: 'https://heyllo.co',
          chatbotId: 'k57prhqstyxvr72v1ss2y18h',
        );

        await chatPlugin.streamResponse(
          message: 'Test message',
        );

        fail('Should throw an exception');
      } catch (e) {
        expect(e, isException);
      }
    });
  });

  group('Chat Widget Integration', () {
    testWidgets('sends and receives messages correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Prepare test data
      const testMessage = 'Integration test message';

      // Find and interact with the TextField
      final textField = find.byType(TextField);
      await tester.enterText(textField, testMessage);
      await tester.pumpAndSettle();

      // Find and tap send button
      final sendButton = find.byIcon(Icons.send);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify the message appears in the chat
      expect(find.text(testMessage), findsOneWidget);

      // Wait for and verify bot response
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify that the text field is cleared
      final currentText = tester.widget<TextField>(textField).controller?.text;
      expect(currentText, isEmpty);
    });

    testWidgets('handles empty messages correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Try to send empty message
      final sendButton = find.byIcon(Icons.send);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify no message was sent (no new chat bubbles)
      final messages = find.byType(Container).evaluate();
      final initialCount = messages.length;

      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      final afterCount = find.byType(Container).evaluate().length;
      expect(afterCount, equals(initialCount));
    });

    testWidgets('shows loading state correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Send a message
      await tester.enterText(find.byType(TextField), 'Test loading state');
      await tester.tap(find.byIcon(Icons.send));

      // Verify loading indicator appears
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for response
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify loading indicator disappears
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('Chat Plugin State Management', () {
    testWidgets('maintains chat history correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Send multiple messages
      final messages = ['Message 1', 'Message 2', 'Message 3'];

      for (final message in messages) {
        await tester.enterText(find.byType(TextField), message);
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify all messages are present
      for (final message in messages) {
        expect(find.text(message), findsOneWidget);
      }
    });

    testWidgets('handles screen rotation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Send a message
      await tester.enterText(find.byType(TextField), 'Test rotation');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Simulate rotation
      await tester.binding.setSurfaceSize(const Size(1018, 1018));
      await tester.pumpAndSettle();

      // Verify message persists
      expect(find.text('Test rotation'), findsOneWidget);
    });
  });

  group('Network Conditions', () {
    testWidgets('handles network timeouts', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // TODO: Implement network condition testing
      // This would require mocking the network layer
    });

    testWidgets('handles reconnection', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // TODO: Implement reconnection testing
      // This would require mocking the SSE connection
    });
  });
}
