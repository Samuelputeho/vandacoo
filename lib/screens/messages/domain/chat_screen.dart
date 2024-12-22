import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/screens/messages/presentation/bloc/message_bloc.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final UserEntity otherUser;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch messages between these two users
    context.read<MessageBloc>().add(FetchMessagesEvent(
          senderId: widget.currentUserId,
          receiverId: widget.otherUser.id,
        ));
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      context.read<MessageBloc>().add(SendMessageEvent(
            senderId: widget.currentUserId,
            receiverId: widget.otherUser.id,
            content: _messageController.text,
          ));

      _messageController.clear();

      // Refresh messages
      context.read<MessageBloc>().add(FetchMessagesEvent(
            senderId: widget.currentUserId,
            receiverId: widget.otherUser.id,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser.name),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<MessageBloc, MessageState>(
              builder: (context, state) {
                if (state is MessageLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orange,
                    ),
                  );
                }

                if (state is MessageFailure) {
                  return Center(
                    child: Text(
                      'Error: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (state is MessageLoaded) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    itemCount: state.messages.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isCurrentUser =
                          message.senderId == widget.currentUserId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? Colors.orange.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(message.content),
                        ),
                      );
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
