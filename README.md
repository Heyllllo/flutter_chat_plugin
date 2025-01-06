# Flutter Chat Plugin

A Flutter plugin for implementing real-time chat functionality with Server-Sent Events (SSE) support. This plugin provides a customizable chat interface and handles message streaming, state management, and error handling.

## Features

- 🚀 Real-time message streaming via SSE
- 💬 Pre-built chat UI components
- 🎨 Customizable chat bubbles and input field
- 🔄 Automatic reconnection handling
- ✨ Message history management
- 🛡️ Error handling and recovery
- 📱 Cross-platform support

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  chat_plugin:
    git:
      url: https://github.com/yourusername/chat_plugin.git
      ref: main
```

### Basic Usage

1. Import the package:
```dart
import 'package:chat_plugin/chat_plugin.dart';
```

2. Use the pre-built ChatWidget:
```dart
ChatWidget(
  baseUrl: 'https://your-api.example.com',
  tenantIndex: 'your-tenant-index',
)
```

### Advanced Usage

For more control over the chat functionality, you can use the ChatPlugin class directly:

```dart
final chatPlugin = ChatPlugin();

// Initialize
await chatPlugin.initialize(
  baseUrl: 'https://your-api.example.com',
  tenantIndex: 'your-tenant-index',
);

// Send a message
final response = await chatPlugin.sendMessage(
  message: 'Hello!',
  chatBotLogId: null, // For first message
);

// Stream the response
chatPlugin
  .streamResponse(
    chatBotLogId: response['chatBotLogId'],
    message: 'Hello!',
  )
  .listen(
    (response) {
      print('Received: $response');
    },
    onError: (error) {
      print('Error: $error');
    },
  );

// Don't forget to dispose
chatPlugin.dispose();
```

## Customization

### Chat Bubble Styling

```dart
ChatWidget(
  baseUrl: 'your-base-url',
  tenantIndex: 'your-tenant-index',
  chatBubbleDecoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
      ),
    ],
  ),
)
```

### Input Field Styling

```dart
ChatWidget(
  baseUrl: 'your-base-url',
  tenantIndex: 'your-tenant-index',
  inputDecoration: InputDecoration(
    hintText: 'Type something...',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25.0),
    ),
    filled: true,
    fillColor: Colors.grey[100],
  ),
)
```

## API Reference

### ChatPlugin

- `initialize({required String baseUrl, required String tenantIndex})`
  - Initializes the chat plugin with the given configuration

- `sendMessage({required String message, int? chatBotLogId})`
  - Sends a message and returns the server response

- `streamResponse({required int chatBotLogId, required String message})`
  - Returns a Stream of responses for the given message

- `saveChatMessage({required String message, required int chatBotLogId, int? chatBotLogMessageId})`
  - Saves a chat message and returns the server response

- `dispose()`
  - Cleans up resources when done

### ChatWidget

A pre-built widget that provides a complete chat interface:

```dart
ChatWidget({
  required String baseUrl,
  required String tenantIndex,
  InputDecoration? inputDecoration,
  BoxDecoration? chatBubbleDecoration,
})
```

## Running Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/plugin_integration_test.dart
```

## Example

Check out the [example](example) directory for a complete implementation.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Requirements

- Flutter: >=3.0.0
- Dart: >=3.0.0

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

