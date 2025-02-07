import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/models/user_model.dart';
import 'package:vandacoo/features/messages/presentation/bloc/messages_bloc/message_bloc.dart';
import 'package:vandacoo/features/messages/presentation/widgets/message_thread_tile.dart';

import '../../domain/entity/message_entity.dart';

class MessagesListPage extends StatefulWidget {
  final String currentUserId;

  const MessagesListPage({
    super.key,
    required this.currentUserId,
  });

  @override
  State<MessagesListPage> createState() => _MessagesListPageState();
}

class _MessagesListPageState extends State<MessagesListPage> {
  @override
  void initState() {
    super.initState();
    print('MessagesListPage initialized');
    _loadData();
  }

  void _loadData() {
    _fetchUsers();
    _fetchMessages();
  }

  void _fetchMessages() {
    print('Fetching all messages for user: ${widget.currentUserId}');
    context.read<MessageBloc>().add(
          FetchAllMessagesEvent(userId: widget.currentUserId),
        );
  }

  void _fetchUsers() {
    print('Fetching all users');
    context.read<MessageBloc>().add(FetchAllUsersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/new-message',
                arguments: {'currentUserId': widget.currentUserId},
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MessageBloc, MessageState>(
        builder: (context, state) {
          print('Current MessageState: ${state.runtimeType}');

          if (state is MessageLoading) {
            print('Messages loading...');
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MessageFailure) {
            print('Message failure: ${state.message}');
            return Center(child: Text(state.message));
          }

          if (state is MessageLoaded) {
            print('Messages loaded: ${state.messages.length} messages');
            if (state.messages.isEmpty) {
              return const Center(child: Text('No messages yet'));
            }

            final messageThreads = _groupMessagesByThread(state.messages);
            print('Grouped into ${messageThreads.length} threads');

            return BlocListener<MessageBloc, MessageState>(
              listener: (context, state) {
                if (state is MessageThreadDeleted) {
                  print('Message thread deleted, refreshing messages...');
                  _fetchMessages();
                }
              },
              child: BlocBuilder<MessageBloc, MessageState>(
                builder: (context, userState) {
                  print('User state: ${userState.runtimeType}');
                  final users = userState is UsersLoaded ? userState.users : [];
                  print('Users loaded: ${users.length}');

                  return ListView.builder(
                    itemCount: messageThreads.length,
                    itemBuilder: (context, index) {
                      final thread = messageThreads[index];
                      final otherUserId =
                          thread.first.senderId == widget.currentUserId
                              ? thread.first.receiverId
                              : thread.first.senderId;

                      final otherUser = users.firstWhere(
                        (user) => user.id == otherUserId,
                        orElse: () {
                          print('User not found for ID: $otherUserId');
                          return UserModel(
                            id: otherUserId,
                            name: 'Unknown User',
                            email: '',
                            bio: '',
                            propic: '',
                            accountType: '',
                            gender: '',
                            age: '',
                            hasSeenIntroVideo: false,
                          );
                        },
                      );

                      print('Building thread tile for user: ${otherUser.name}');

                      return Dismissible(
                        key: Key(otherUserId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          print(
                              'Dismissing thread with otherUserId: $otherUserId');
                          context.read<MessageBloc>().add(
                                DeleteMessageThreadEvent(
                                  userId: widget.currentUserId,
                                  otherUserId: otherUserId,
                                ),
                              );
                        },
                        child: MessageThreadTile(
                          messages: thread,
                          currentUserId: widget.currentUserId,
                          otherUser: otherUser,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: {
                              'currentUserId': widget.currentUserId,
                              'otherUserId': otherUserId,
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }

          print('No relevant state found, showing empty container');
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  List<List<MessageEntity>> _groupMessagesByThread(
      List<MessageEntity> messages) {
    final Map<String, List<MessageEntity>> threads = {};

    for (final message in messages) {
      final threadKey = [message.senderId, message.receiverId]..sort();
      final key = threadKey.join('-');

      if (!threads.containsKey(key)) {
        threads[key] = [];
      }
      threads[key]!.add(message);
    }

    return threads.values.toList()
      ..sort((a, b) => b.first.createdAt.compareTo(a.first.createdAt));
  }
}
