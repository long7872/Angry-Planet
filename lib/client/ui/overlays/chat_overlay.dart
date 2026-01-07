import 'package:flutter/material.dart';

class ChatMessage {
  final String playerName;
  final String message;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.playerName,
    required this.message,
    required this.timestamp,
    required this.isMe,
  });
}

class ChatOverlay extends StatefulWidget {
  final Function(String) onSendMessage;
  final List<ChatMessage> messages;
  final VoidCallback onClose;

  const ChatOverlay({
    Key? key,
    required this.onSendMessage,
    required this.messages,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    widget.onSendMessage(message);
    _messageController.clear();

    // Auto-scroll to bottom
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final isMobile = size.width < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Positioned(
          left: isMobile ? 0 : 20,
          right: isMobile ? 0 : null,
          bottom: isMobile ? 0 : 120,
          child: Container(
            width: isMobile ? size.width : 350,
            height: isMobile ? size.height * 0.45 : 400,
            margin: isMobile
                ? EdgeInsets.zero
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(isMobile ? 16 : 15),
                bottom: Radius.circular(isMobile ? 0 : 15),
              ),
              border: Border.all(color: Colors.cyan, width: 2),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildMessageList()),
                  _buildInput(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(13),
          topRight: Radius.circular(13),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.chat, color: Colors.cyan, size: 20),
          SizedBox(width: 8),
          Text(
            'Chat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white70, size: 20),
            onPressed: widget.onClose,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (widget.messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet...',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(10),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final msg = widget.messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
    final isAI = msg.playerName == 'AI Assistant';

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Player name and time
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!msg.isMe) ...[
                if (isAI)
                  Icon(Icons.smart_toy, color: Colors.purple, size: 12),
                if (isAI)
                  SizedBox(width: 4),
                Text(
                  msg.playerName,
                  style: TextStyle(
                    color: isAI ? Colors.purple : Colors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
              ],
              Text(
                timeStr,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
              if (msg.isMe) ...[
                SizedBox(width: 6),
                Text(
                  'You',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 4),

          // Message bubble
          Container(
            constraints: BoxConstraints(maxWidth: 250),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isAI
                  ? Colors.purple.withOpacity(0.2)
                  : msg.isMe
                      ? Colors.cyan.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isAI
                    ? Colors.purple.withOpacity(0.5)
                    : msg.isMe ? Colors.cyan.withOpacity(0.5) : Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              msg.message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(13),
          bottomRight: Radius.circular(13),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Type a message... (use @AI for help)',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLength: 200,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return null; // Hide counter
              },
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.cyan,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}