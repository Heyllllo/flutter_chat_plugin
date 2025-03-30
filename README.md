# Heyllo AI ChatBot Plugin for Flutter

A Flutter plugin for easily integrating AI powered chatbots into your mobile applications through [Heyllo.co](https://heyllo.co). This plugin provides a fully customizable chat interface that connects to Heyllo's AI-powered chatbots.

## Features

- 🧠 Integrate AI-powered chatbots with minimal setup
- 🎨 Fully customizable UI with comprehensive theme support
- 🔄 Real-time streaming responses with animated typing indicators
- 📱 Works across all Flutter platforms (iOS, Android)
- 🧩 Easy to integrate with existing Flutter apps
- 💬 Rich message bubbles with avatars and timestamps
- 🛠️ Advanced error handling and debugging support

## Prerequisites

Before using this plugin, you need to:

1. Create a chatbot at [Heyllo.co](https://heyllo.co)
2. Train your chatbot with your own data
3. Get your chatbot ID and domain details from the Export tab in your Heyllo dashboard

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  heyllo_ai_chatbot: ^1.0.0
```

Run `flutter pub get` to install the plugin.

## Basic Usage (For Beginners)

The simplest way to add a Heyllo AI chatbot to your app, perfect if you have little to no knowledge of complex Flutter development:

```dart
import 'package:flutter/material.dart';
import 'package:heyllo_ai_chatbot/chat_plugin.dart';

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

  @override
  Widget build(BuildContext context) {
    // Replace with your chatbot ID from Heyllo.co
    const chatbotId = 'your_chatbot_id_here';
    const domain = 'https://heyllo.co';

    return Scaffold(
      appBar: AppBar(title: const Text('My AI Assistant')),
      body: const ChatWidget(
        domain: domain,
        chatbotId: chatbotId,
      ),
    );
  }
}
```

## Intermediate Usage

For those who want to customize the appearance and add callbacks:

```dart
ChatWidget(
  domain: 'https://heyllo.co',
  chatbotId: 'your_chatbot_id_here',
  theme: ChatTheme(
    userBubbleColor: Colors.blue,
    botBubbleColor: Colors.grey[200],
    userTextStyle: const TextStyle(color: Colors.white),
    botTextStyle: const TextStyle(color: Colors.black87),
    backgroundColor: Colors.white,
    inputDecoration: InputDecoration(
      hintText: 'Ask me anything...',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      filled: true,
      fillColor: Colors.grey[100],
    ),
  ),
  showTimestamps: true,
  inputPlaceholder: 'Type your question...',
  sendButtonIcon: Icons.send_rounded,
  initialMessages: [
    ChatMessage(
      message: 'Hello! How can I help you today?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ],
  onMessageSent: (message) {
    print('User sent: $message');
  },
  onResponseReceived: (response) {
    print('Bot responded: $response');
  },
  onError: (error) {
    print('Error occurred: $error');
  },
)
```

## Advanced Usage

For developers who need more control or want to deeply customize the chat experience:

### Using the ChatService Directly

```dart
class CustomChatScreen extends StatefulWidget {
  const CustomChatScreen({super.key});

  @override
  State<CustomChatScreen> createState() => _CustomChatScreenState();
}

class _CustomChatScreenState extends State<CustomChatScreen> {
  final _chatService = ChatService();
  final _textController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initChat();
  }
  
  Future<void> _initChat() async {
    await _chatService.initialize(
      domain: 'https://heyllo.co',
      chatbotId: 'your_chatbot_id_here',
    );
    
    // Add a welcome message
    _chatService.addDirectMessage(
      const ChatMessage(
        message: 'Welcome! I\'m your custom AI assistant.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Chat UI'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: _chatService,
              builder: (context, _) {
                return ListView.builder(
                  reverse: true,
                  itemCount: _chatService.messages.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final message = _chatService.messages[
                      _chatService.messages.length - 1 - index
                    ];
                    
                    return ChatBubble(
                      message: message,
                      theme: ChatTheme.fromTheme(theme),
                      showAvatar: true,
                      showTimestamp: true,
                      senderName: message.isUser ? 'You' : 'AI Assistant',
                      onTap: () {
                        // Handle message tap
                      },
                    );
                  },
                );
              },
            ),
          ),
          
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
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      _chatService.sendMessage(_textController.text);
                      _textController.clear();
                    }
                  },
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
    _chatService.dispose();
    _textController.dispose();
    super.dispose();
  }
}
```

### Creating Custom Themes

```dart
// Define multiple themes that users can switch between
final Map<String, ChatTheme> chatThemes = {
  'Light': const ChatTheme(
    userBubbleColor: Colors.blue,
    botBubbleColor: Color(0xFFF0F0F0),
    userTextStyle: TextStyle(color: Colors.white),
    botTextStyle: TextStyle(color: Colors.black87),
    backgroundColor: Colors.white,
  ),
  
  'Dark': const ChatTheme(
    userBubbleColor: Colors.indigo,
    botBubbleColor: Color(0xFF2D2D2D),
    userTextStyle: TextStyle(color: Colors.white),
    botTextStyle: TextStyle(color: Colors.white),
    backgroundColor: Color(0xFF121212),
    loadingIndicatorColor: Colors.white70,
  ),
  
  'Playful': ChatTheme(
    userBubbleColor: Colors.orange,
    botBubbleColor: Colors.purple.shade50,
    userTextStyle: const TextStyle(color: Colors.white),
    botTextStyle: const TextStyle(color: Colors.purple),
    userBubbleBorderRadius: BorderRadius.circular(24),
    botBubbleBorderRadius: BorderRadius.circular(24),
    inputDecoration: InputDecoration(
      hintText: 'Say something fun...',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
  ),
};

// Use the theme in your widget
ChatWidget(
  domain: 'https://heyllo.co',
  chatbotId: 'your_chatbot_id_here',
  theme: chatThemes[selectedTheme], // Selected by user
)
```

## Customizing the Typing Indicator

The plugin comes with a customizable bubble typing indicator:

```dart
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
3. Go to the Export tab in your dashboard
4. Find your chatbot ID and domain in the API integration section
5. Copy these details to use in your Flutter app

## Troubleshooting

If you encounter issues with the connection:

1. Double-check your chatbot ID and domain
2. Ensure your device has internet connectivity
3. Check if your chatbot is active on the Heyllo platform
4. Enable debugging to see detailed logs:

```dart
// To enable verbose logs for SSE connection
// Add this before using the ChatWidget
debugPrint('Enabling SSE debug logs');
```

## Complete Example

Check the `example` folder in the repository for a complete working sample app, including theme switching and advanced customization.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## About Heyllo Co

[Heyllo Co](https://heyllo.co) provides AI-powered chatbots that you can easily train with your own data. Create your own chatbot in minutes without any coding skills required.