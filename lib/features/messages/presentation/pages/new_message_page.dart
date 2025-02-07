import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/features/messages/presentation/bloc/messages_bloc/message_bloc.dart';

class NewMessagePage extends StatefulWidget {
  final String currentUserId;

  const NewMessagePage({
    super.key,
    required this.currentUserId,
  });

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  @override
  void initState() {
    super.initState();
    context.read<MessageBloc>().add(FetchAllUsersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
      ),
      body: BlocBuilder<MessageBloc, MessageState>(
        builder: (context, state) {
          if (state is MessageLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MessageFailure) {
            return Center(child: Text(state.message));
          }
          if (state is UsersLoaded) {
            if (state.users.isEmpty) {
              return const Center(child: Text('No users found'));
            }

            final filteredUsers = state.users
                .where((user) => user.id != widget.currentUserId)
                .toList();

            return ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user.name[0].toUpperCase()),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/chat',
                      arguments: {
                        'currentUserId': widget.currentUserId,
                        'otherUserId': user.id,
                      },
                    );
                  },
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
