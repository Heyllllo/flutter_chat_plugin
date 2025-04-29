# Heyllo AI ChatBot Plugin for Flutter

A Flutter plugin for easily integrating AI powered chatbots into your mobile applications through [Heyllo.co](https://heyllo.co). This plugin provides a fully customizable chat interface that connects to Heyllo's AI-powered chatbots.

## Features

- 🧠 Integrate AI-powered chatbots with minimal setup.
- 🎨 Fully customizable UI with comprehensive theme support.
- 🔄 Real-time streaming responses with animated typing indicators.
- 📱 Works across all Flutter platforms (iOS, Android, Web - *check compatibility*).
- 🧩 Easy to integrate with existing Flutter apps.
- 💬 Rich message bubbles with optional avatars and timestamps.
- 🔗 **Markdown Support:** Renders bot responses using Markdown syntax (bold, italics, lists, links, etc.).
- 📄 **Citation Handling:** Displays citation sources provided by the backend.
- ⚙️ **Configurable Features:** Toggle display of citations (`showCitations`) and enable/disable the entire chat widget (`isEnabled`).
- 🆔 **Conversation Context:** Maintains conversation state using `thread_id`.
- 🛠️ Advanced error handling and specific callbacks (`onCitationsReceived`, `onThreadIdReceived`).

## Prerequisites

Before using this plugin, you need to:

1. Create a chatbot at [Heyllo.co](https://heyllo.co)
2. Train your chatbot with your own data
3. Get your chatbot ID and domain details from the Export tab in your Heyllo dashboard

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  heyllo_ai_chatbot: ^0.0.3 # Use the latest version
  flutter_markdown: ^0.7.1 # Required for Markdown rendering
  url_launcher: ^6.2.6    # For opening links in Markdown/Citations
```

Run `flutter pub get` to install the dependencies.

## Basic Usage

The simplest way to add a Heyllo AI chatbot to your app:

```dart
import 'package:flutter/material.dart';
import 'package:heyllo_ai_chatbot/heyllo_ai_chatbot.dart'; // Import the main package

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Chatbot App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ChatbotScreen(),
    );
  }
}

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  // Replace with your chatbot ID and domain from Heyllo.co
  static const String chatbotId = 'your_chatbot_id_here';
  static const String domain = 'https://heyllo.co';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My AI Assistant')),
      body: const ChatWidget(
        // Required parameters
        domain: domain,
        chatbotId: chatbotId,

        // Optional parameters (defaults are usually fine)
        // isEnabled: true,
        // showCitations: false,
        // showTimestamps: false,
      ),
    );
  }
}
```

## Intermediate Usage

Customize the appearance and handle events:

```dart
ChatWidget(
  domain: 'https://heyllo.co',
  chatbotId: 'your_chatbot_id_here',
  theme: ChatTheme( // Customize theme properties
    userBubbleColor: Colors.deepPurple,
    botBubbleColor: Colors.grey[200],
    userTextStyle: const TextStyle(color: Colors.white),
    botTextStyle: const TextStyle(color: Colors.black87),
    backgroundColor: Colors.white,
    inputDecoration: InputDecoration(
      hintText: 'Ask me anything...',
      border: OutlineInputBorder( borderRadius: BorderRadius.circular(24) ),
      filled: true,
      fillColor: Colors.grey[100],
    ),
    sendButtonColor: Colors.deepPurple,
  ),
  // Control features
  isEnabled: true, // Default: true
  showTimestamps: true, // Default: false
  showCitations: true, // Default: false

  // Customize UI elements
  inputPlaceholder: 'Type your question...',
  sendButtonIcon: Icons.send_rounded,

  // Provide initial messages (ensure 'type' is set)
  initialMessages: [
    ChatMessage(
      message: 'Hello! Ask me about our services.',
      isUser: false,
      type: 'content', // Add message type
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ],

  // Handle callbacks
  onMessageSent: (message) {
    print('User sent: $message');
  },
  onResponseReceived: (response) { // Final combined text content
    print('Bot final response text: $response');
  },
  onCitationsReceived: (citations) {
    print('Received ${citations.length} citations: $citations');
    // Handle citations if needed externally
  },
  onThreadIdReceived: (threadId) {
    print('Received thread ID: $threadId');
    // Store or use the thread ID
  },
  onError: (error) {
    print('Chat Error occurred: $error');
    // Display error to user, e.g., via SnackBar
  },
)
```

## Advanced Usage

For developers who need fine-grained control using ChatService:

```dart
import 'package:flutter/material.dart';
import 'package:heyllo_ai_chatbot/heyllo_ai_chatbot.dart';

class CustomChatScreen extends StatefulWidget {
  const CustomChatScreen({super.key});

  @override
  State<CustomChatScreen> createState() => _CustomChatScreenState();
}

class _CustomChatScreenState extends State<CustomChatScreen> {
  // Use ChatService directly for state management
  final _chatService = ChatService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController(); // For managing scroll position

  // Configuration
  static const String chatbotId = 'your_chatbot_id_here';
  static const String domain = 'https://heyllo.co';

  // UI/Feature Flags
  bool _showTimestamps = true;
  bool _showCitations = true; // Example: Enable citations

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      await _chatService.initialize(
        domain: domain,
        chatbotId: chatbotId,
      );
      // Add a welcome message (ensure type is set)
      _chatService.addDirectMessage(
        ChatMessage(
          message: 'Welcome! I\'m your custom AI assistant. How can I help?',
          isUser: false,
          type: 'content', // Specify message type
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print("Failed to initialize chat: $e");
      // Handle initialization error in UI
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      print("Sending message: $text");
      // Call service with desired callbacks
      _chatService.sendMessage(
        text,
        onError: (error) => print("Error sending message: $error"),
        onThreadIdReceived: (id) => print("Context Thread ID: $id"),
        onCitationsReceived: (citations) => print("Got citations: $citations")
      );
      _textController.clear();
      FocusScope.of(context).unfocus(); // Hide keyboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Create a ChatTheme instance for the bubbles
    final chatTheme = ChatTheme.fromTheme(theme).merge(const ChatTheme(
      // Add any specific theme overrides here if needed
      // e.g., botBubbleColor: Colors.lightGreen[100],
    ));

    return Scaffold(
      appBar: AppBar( title: const Text('Custom Chat UI') ),
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: _chatService,
              builder: (context, _) {
                // Scroll to bottom logic (optional but recommended)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  // reverse: true, // Use reverse OR scrollController logic
                  padding: const EdgeInsets.all(8),
                  itemCount: _chatService.messages.length,
                  itemBuilder: (context, index) {
                    final message = _chatService.messages[index];
                    // Render each message using ChatBubble
                    return ChatBubble(
                      message: message,
                      theme: chatTheme, // Pass the theme
                      showAvatar: !message.isUser, // Show avatar for bot
                      showTimestamp: _showTimestamps, // Use state variable
                      showCitations: _showCitations, // Use state variable
                      isError: message.type == 'error', // Style error messages
                      // senderName: message.isUser ? 'You' : 'AI Assistant', // Optional
                    );
                  },
                );
              },
            ),
          ),

          // Custom Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration( hintText: 'Type a message...', border: InputBorder.none ),
                    onSubmitted: (_) => _sendMessage(), // Send on keyboard action
                  ),
                ),
                // Use ListenableBuilder to disable button while loading
                ListenableBuilder(
                  listenable: _chatService,
                  builder: (context, _) {
                    return IconButton(
                      icon: _chatService.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.send, color: theme.colorScheme.primary),
                      onPressed: _chatService.isLoading ? null : _sendMessage,
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatService.dispose(); // IMPORTANT: Dispose the service
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

## Creating Custom Themes

```dart
// Define multiple themes that users can switch between
final Map<String, ChatTheme> chatThemes = {
  'Light': const ChatTheme( /* ... theme properties ... */ ),
  'Dark': const ChatTheme( /* ... theme properties ... */ ),
  'Playful': ChatTheme( /* ... theme properties ... */ ),
};

// Use the theme in your widget
ChatWidget(
  domain: 'https://heyllo.co',
  chatbotId: 'your_chatbot_id_here',
  theme: chatThemes[selectedTheme], // Selected by user
)
```

## Customizing the Typing Indicator

The BubbleTypingIndicator is used internally but can also be used standalone:

```dart
import 'package:heyllo_ai_chatbot/src/widgets/typing_indicator.dart'; // Direct import if needed

BubbleTypingIndicator(
  color: Colors.grey, // Custom color
  bubbleSize: 10.0,   // Size of each bubble
  spacing: 5.0,       // Space between bubbles
  bubbleCount: 3,     // Number of bubbles
  animationDuration: const Duration(milliseconds: 1500),
)
```

## How to Get Your Chatbot ID

1. Create an account at [Heyllo.co](https://heyllo.co)
2. Create a new chatbot and train it with your content
3. Go to the Export tab in your chatbot dashboard
4. Find your Chatbot ID and Domain (usually https://heyllo.co) in the API integration section
5. Copy these details to use in your Flutter app

## Troubleshooting

If you encounter issues:

- **Verify Credentials**: Double-check your chatbotId and domain.
- **Check Internet**: Ensure your device has network connectivity.
- **Check Chatbot Status**: Confirm your chatbot is active on the Heyllo platform.
- **Review Logs**: Check the debug console in your Flutter app for logs prefixed with `📡 Chat Plugin:` or `ChatService:`. These logs provide detailed information about connection attempts, data received, and errors. Enable kDebugMode for more verbose logs.
- **Check pubspec.yaml**: Ensure heyllo_ai_chatbot and flutter_markdown are correctly listed under dependencies.
- **Report Issues**: If problems persist, consider opening an issue on the plugin's repository (if available).

## Complete Example

Check the example folder in the repository for a complete working sample app, including theme switching and advanced customization.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## About Heyllo Co

Heyllo[https://heyllo.co/] provides AI-powered chatbots that you can easily train with your own data. Create your own chatbot in minutes without any coding skills required.