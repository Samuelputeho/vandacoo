import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/features/messages/domain/entity/message_entity.dart';
import 'package:vandacoo/features/messages/presentation/widgets/message_screen_tile.dart';
import 'package:vandacoo/features/messages/presentation/bloc/message_bloc.dart';
import 'package:vandacoo/features/messages/presentation/bloc/users_bloc.dart';
import 'package:vandacoo/features/messages/presentation/widgets/users_screen.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';

import '../../../../core/constants/colors.dart';

class MessagesScreen extends StatefulWidget {
  final UserEntity user;
  const MessagesScreen({
    super.key,
    required this.user,
  });

  @override
  // ignore: library_private_types_in_public_api
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  late String currentUserId;
  Map<String, UserEntity> userMap = {};

  @override
  void initState() {
    super.initState();
    currentUserId = widget.user.id;
    _fetchMessages();
    context.read<UsersBloc>().add(GetAllUsersEvent());
  }

  void _fetchMessages() {
    context.read<MessageBloc>().add(FetchMessagesEvent(
          senderId: currentUserId,
        ));
  }

  // Helper method to group messages by conversation
  Map<String, List<MessageEntity>> _groupMessagesByConversation(
      List<MessageEntity> messages) {
    final Map<String, List<MessageEntity>> conversations = {};

    for (final message in messages) {
      final otherUserId = message.senderId == currentUserId
          ? message.receiverId
          : message.senderId;

      if (!conversations.containsKey(otherUserId)) {
        conversations[otherUserId] = [];
      }
      conversations[otherUserId]!.add(message);
    }

    return conversations;
  }

  void _selectUserAndMessage() async {
    final selectedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UsersScreen(user: widget.user),
      ),
    );

    if (selectedUser != null) {
      _showMessageDialog(selectedUser);
    }
  }

  void _showMessageDialog(UserEntity selectedUser) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Message to ${selectedUser.name}'),
          content: TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  context.read<MessageBloc>().add(SendMessageEvent(
                        senderId: currentUserId,
                        receiverId: selectedUser.id,
                        content: _messageController.text,
                      ));

                  _messageController.clear();
                  Navigator.of(context).pop();

                  context.read<MessageBloc>().add(FetchMessagesEvent(
                        senderId: currentUserId,
                        receiverId: selectedUser.id,
                      ));
                }
              },
              child: const Text('Send'),
            ),
            TextButton(
              onPressed: () {
                _messageController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _selectUserAndMessage,
          ),
        ],
      ),
      body: BlocBuilder<UsersBloc, UsersState>(
        builder: (context, usersState) {
          if (usersState is UsersLoaded) {
            userMap = {for (var user in usersState.users) user.id: user};
          }

          return BlocBuilder<MessageBloc, MessageState>(
            builder: (context, messageState) {
              if (messageState is MessageLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                );
              }

              if (messageState is MessageLoaded) {
                if (messageState.messages.isEmpty) {
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

                final conversations =
                    _groupMessagesByConversation(messageState.messages);

                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final otherUserId = conversations.keys.elementAt(index);
                    final messages = conversations[otherUserId]!;
                    final lastMessage = messages.first;

                    // Get the other user from userMap
                    final otherUser = userMap[otherUserId] ??
                        UserEntity(
                          id: otherUserId,
                          name: 'User $otherUserId',
                          email: '',
                          bio: '',
                          accountType: 'individual',
                          gender: 'Prefer not to say',
                          age: '13s',
                        );

                    return MessageScreenTile(
                      image: otherUser.propic,
                      name: otherUser.name,
                      message: lastMessage.content,
                      currentUserId: currentUserId,
                      otherUser: otherUser,
                    );
                  },
                );
              }

              if (messageState is MessageFailure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${messageState.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchMessages,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return const Center(
                child: Text(
                  'Start a conversation!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
