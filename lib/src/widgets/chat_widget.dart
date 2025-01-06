// lib/src/widgets/chat_widget.dart
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';

class ChatWidget extends StatefulWidget {
  final String baseUrl;
  final String tenantIndex;
  final InputDecoration? inputDecoration;
  final BoxDecoration? chatBubbleDecoration;

  const ChatWidget({
    Key? key,
    required this.baseUrl,
    required this.tenantIndex,
    this.inputDecoration,
    this.chatBubbleDecoration,
  }) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final _chatService = ChatService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _chatService.initialize(
      baseUrl: widget.baseUrl,
      tenantIndex: widget.tenantIndex,
    );
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    _chatService.sendMessage(_textController.text);
    _textController.clear();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: widget.chatBubbleDecoration ??
            BoxDecoration(
              color: message.isUser ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black,
              ),
            ),
            if (message.isWaiting)
              const SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: _chatService,
            builder: (context, _) {
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: _chatService.messages.length,
                itemBuilder: (context, index) {
                  final message = _chatService
                      .messages[_chatService.messages.length - 1 - index];
                  return _buildMessageBubble(message);
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: widget.inputDecoration ??
                      const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.send,
                  color: _chatService.isLoading
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).primaryColor,
                ),
                onPressed: _chatService.isLoading ? null : _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _chatService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
