import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/common/models/user_model.dart';
import 'package:vandacoo/features/messages/domain/entity/message_entity.dart';
import 'package:vandacoo/features/messages/presentation/bloc/messages_bloc/message_bloc.dart';
import 'package:vandacoo/features/messages/presentation/widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserProPic;

  const ChatPage({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserProPic,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  UserEntity? otherUser;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    otherUser = UserModel(
      id: widget.otherUserId,
      name: widget.otherUserName,
      propic: widget.otherUserProPic,
      email: '',
      bio: '',
      accountType: '',
      gender: '',
      age: '',
      hasSeenIntroVideo: false,
    );
    _fetchMessages();
  }

  void _fetchMessages() {
    context.read<MessageBloc>().add(
          FetchMessagesEvent(
            senderId: widget.currentUserId,
            receiverId: widget.otherUserId,
          ),
        );
  }

  Future<void> _pickMedia(MessageType type) async {
    final XFile? file = await (type == MessageType.image
        ? _picker.pickImage(source: ImageSource.gallery)
        : _picker.pickVideo(source: ImageSource.gallery));

    if (file != null) {
      if (!mounted) return;

      context.read<MessageBloc>().add(
            SendMessageEvent(
              senderId: widget.currentUserId,
              receiverId: widget.otherUserId,
              content: 'Sent ${type.toString().split('.').last}',
              messageType: type,
              mediaFile: File(file.path),
            ),
          );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    context.read<MessageBloc>().add(
          SendMessageEvent(
            senderId: widget.currentUserId,
            receiverId: widget.otherUserId,
            content: _messageController.text.trim(),
          ),
        );

    _messageController.clear();
  }

  void _handleMessageDelete(String messageId) {
    context.read<MessageBloc>().add(
          DeleteMessageEvent(
            messageId: messageId,
            userId: widget.currentUserId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Refresh messages list when going back
        context.read<MessageBloc>().add(
              FetchAllMessagesEvent(userId: widget.currentUserId),
            );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.otherUserName,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Refresh messages list before popping
              context.read<MessageBloc>().add(
                    FetchAllMessagesEvent(userId: widget.currentUserId),
                  );
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Conversation'),
                    content: const Text(
                        'Are you sure you want to delete this conversation?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<MessageBloc>().add(
                                DeleteMessageThreadEvent(
                                  userId: widget.currentUserId,
                                  otherUserId: widget.otherUserId,
                                ),
                              );
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Return to messages list
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocConsumer<MessageBloc, MessageState>(
                listener: (context, state) {
                  if (state is MessageSent || state is MessageDeleted) {
                    _fetchMessages();
                  }
                  if (state is MessageFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${state.message}')),
                    );
                  }
                  if (state is UsersLoaded && _isInitialLoad) {
                    otherUser = state.users.firstWhere(
                      (u) => u.id == widget.otherUserId,
                      orElse: () => UserModel(
                        id: widget.otherUserId,
                        name: 'Unknown User',
                        email: '',
                        bio: '',
                        propic: '',
                        accountType: '',
                        gender: '',
                        age: '',
                        hasSeenIntroVideo: false,
                      ),
                    );
                    _isInitialLoad = false;
                  }
                },
                buildWhen: (previous, current) {
                  return current is MessageLoading ||
                      current is MessageLoaded ||
                      current is MessageFailure;
                },
                builder: (context, state) {
                  if (state is MessageLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is MessageFailure) {
                    return Center(child: Text(state.message));
                  }
                  if (state is MessageLoaded) {
                    if (state.messages.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final isFromMe =
                            message.senderId == widget.currentUserId;

                        if (!isFromMe && message.readAt == null) {
                          context.read<MessageBloc>().add(
                                MarkMessageAsReadEvent(messageId: message.id),
                              );
                        }

                        return MessageBubble(
                          message: message,
                          isFromMe: isFromMe,
                          onDelete: isFromMe ? _handleMessageDelete : null,
                          senderName: isFromMe ? 'You' : widget.otherUserName,
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: () => _pickMedia(MessageType.image),
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam),
                      onPressed: () => _pickMedia(MessageType.video),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
