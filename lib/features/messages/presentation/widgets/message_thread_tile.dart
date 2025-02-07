import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/features/messages/domain/entity/message_entity.dart';

class MessageThreadTile extends StatelessWidget {
  final List<MessageEntity> messages;
  final String currentUserId;
  final VoidCallback onTap;
  final UserEntity? otherUser;
  final String recipientName;
  final String recipientProfilePicture;

  const MessageThreadTile({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.onTap,
    this.otherUser,
    required this.recipientName,
    required this.recipientProfilePicture,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = messages.first;
    final isLastMessageFromMe = lastMessage.senderId == currentUserId;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: recipientProfilePicture.isNotEmpty
            ? NetworkImage(recipientProfilePicture)
            : null,
        child: recipientProfilePicture.isEmpty
            ? Text(recipientName[0].toUpperCase())
            : null,
      ),
      title: Text(
        recipientName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Row(
        children: [
          if (lastMessage.messageType != MessageType.text)
            Icon(
              lastMessage.messageType == MessageType.image
                  ? Icons.image
                  : Icons.videocam,
              size: 16,
              color: Colors.grey,
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              lastMessage.messageType == MessageType.text
                  ? lastMessage.content
                  : '${lastMessage.messageType.toString().split('.').last} message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeago.format(lastMessage.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          if (lastMessage.readAt == null && !isLastMessageFromMe)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
