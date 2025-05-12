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
        title: const Text('New Message',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      body: BlocBuilder<MessageBloc, MessageState>(
        builder: (context, state) {
          if (state is MessageLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MessageFailure) {
            return Center(child: Text(state.message));
          }
          if (state is UsersLoaded || state is MessageLoaded) {
            final users = state is UsersLoaded ? state.users : (state as MessageLoaded).users;
            if (users.isEmpty) {
              return const Center(child: Text('No users found'));
            }

            final filteredUsers = users
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
                        'otherUserName': user.name,
                        'otherUserProPic': user.propic,
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
