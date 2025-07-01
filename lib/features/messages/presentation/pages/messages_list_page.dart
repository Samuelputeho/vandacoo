import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/models/user_model.dart';
import 'package:vandacoo/core/common/widgets/loader.dart';
import 'package:vandacoo/features/messages/presentation/bloc/messages_bloc/message_bloc.dart';
import 'package:vandacoo/features/messages/presentation/widgets/message_thread_tile.dart';

import '../../../../core/common/entities/message_entity.dart';

class MessagesListPage extends StatefulWidget {
  final String currentUserId;

  const MessagesListPage({super.key, required this.currentUserId});

  @override
  State<MessagesListPage> createState() => _MessagesListPageState();
}

class _MessagesListPageState extends State<MessagesListPage> {
  MessageLoaded? _currentLoadedState;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // Refresh data when page becomes focused (e.g., when navigating back)
        _loadData();
      }
    });
    print('MessagesListPage initialized with userId: ${widget.currentUserId}');
    _loadData();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _loadData() {
    if (mounted) {
      print('Loading data...');
      // Fetch both messages and users in one go
      context
          .read<MessageBloc>()
          .add(FetchAllMessagesEvent(userId: widget.currentUserId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              final shouldRefresh = await Navigator.pushNamed(
                context,
                '/new-message',
                arguments: {'currentUserId': widget.currentUserId},
              );

              if (shouldRefresh == true) {
                _loadData();
              }
            },
          ),
        ],
      ),
      body: Focus(
        focusNode: _focusNode,
        child: BlocBuilder<MessageBloc, MessageState>(
          buildWhen: (previous, current) {
            // Always rebuild for MessageLoaded and MessageFailure
            if (current is MessageLoaded || current is MessageFailure)
              return true;
            // Only rebuild for MessageLoading on initial load
            if (current is MessageLoading && _currentLoadedState == null)
              return true;
            // Rebuild for UnreadMessagesLoaded if we have a current state
            if (current is UnreadMessagesLoaded && _currentLoadedState != null)
              return true;
            return false;
          },
          builder: (context, state) {
            // Handle MessageLoaded state
            if (state is MessageLoaded) {
              _currentLoadedState = state;
              return _buildMessageList(state);
            }

            // Handle MessageFailure state
            if (state is MessageFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Show loading state only on initial load
            if (state is MessageLoading && _currentLoadedState == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //CircularProgressIndicator(),

                    Loader(),
                    SizedBox(height: 16),
                    Text('Loading messages...'),
                  ],
                ),
              );
            }

            // If we have a current state, show it while loading
            if (_currentLoadedState != null) {
              return _buildMessageList(_currentLoadedState!);
            }

            // Default to loading state
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //CircularProgressIndicator(),
                  Loader(),
                  SizedBox(height: 16),
                  Text('Loading messages...'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageList(MessageLoaded state) {
    if (state.messages.isEmpty) {
      // If we have a current loaded state but no messages, show loading instead of "No messages yet"
      if (_currentLoadedState != null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Loader(),
            ],
          ),
        );
      }
      return const Center(child: Text('No messages yet'));
    }

    final messageThreads = _groupMessagesByThread(state.messages);
    final users = state.users;

    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: ListView.builder(
        itemCount: messageThreads.length,
        itemBuilder: (context, index) {
          final thread = messageThreads[index];
          final otherUserId = thread.first.senderId == widget.currentUserId
              ? thread.first.receiverId
              : thread.first.senderId;

          final otherUser = users.firstWhere(
            (user) => user.id == otherUserId && user.name.isNotEmpty,
            orElse: () {
              // If users list is empty or user not found, show loading state
              // This indicates data is still being loaded
              return UserModel(
                id: otherUserId,
                name: '', // Empty name will trigger loading state
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

          // If user name is empty, show loading state
          if (otherUser.name.isEmpty) {
            return const SizedBox(
              height: 80, // Match the height of MessageThreadTile
              child: Center(child: Loader()),
            );
          }

          // Count unread messages in this thread
          final unreadCount = _countUnreadMessagesInThread(thread);

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
              recipientName: otherUser.name,
              recipientProfilePicture: otherUser.propic,
              unreadCount: unreadCount,
              onTap: () => Navigator.pushNamed(
                context,
                '/chat',
                arguments: {
                  'currentUserId': widget.currentUserId,
                  'otherUserId': otherUserId,
                  'otherUserName': otherUser.name,
                  'otherUserProPic': otherUser.propic,
                },
              ),
            ),
          );
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

  /// Counts unread messages in a thread for the current user
  int _countUnreadMessagesInThread(List<MessageEntity> thread) {
    return thread
        .where((message) =>
            message.receiverId ==
                widget.currentUserId && // Message is for current user
            message.readAt == null) // Message is unread
        .length;
  }
}
