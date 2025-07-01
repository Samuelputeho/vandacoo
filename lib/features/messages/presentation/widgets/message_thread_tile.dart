import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/common/entities/message_entity.dart';

class MessageThreadTile extends StatelessWidget {
  final List<MessageEntity> messages;
  final String currentUserId;
  final VoidCallback onTap;
  final UserEntity? otherUser;
  final String recipientName;
  final String recipientProfilePicture;
  final int unreadCount;

  const MessageThreadTile({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.onTap,
    this.otherUser,
    required this.recipientName,
    required this.recipientProfilePicture,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = messages.first;
    final isLastMessageFromMe = lastMessage.senderId == currentUserId;
    final hasUnreadMessages = unreadCount > 0;

    return Container(
      color: hasUnreadMessages
          ? Theme.of(context).primaryColor.withOpacity(0.05)
          : null,
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: recipientProfilePicture.isNotEmpty
                  ? NetworkImage(recipientProfilePicture)
                  : null,
              child: recipientProfilePicture.isEmpty
                  ? Text(recipientName[0].toUpperCase())
                  : null,
            ),
            if (hasUnreadMessages)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          recipientName,
          style: TextStyle(
            fontWeight: hasUnreadMessages ? FontWeight.w700 : FontWeight.bold,
            color: hasUnreadMessages
                ? Theme.of(context).textTheme.titleMedium?.color
                : null,
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
                  color: hasUnreadMessages
                      ? Theme.of(context).textTheme.bodyMedium?.color
                      : Colors.grey[600],
                  fontWeight:
                      hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
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
                    color: hasUnreadMessages
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                    fontWeight:
                        hasUnreadMessages ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
            if (hasUnreadMessages)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (lastMessage.readAt == null && !isLastMessageFromMe)
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
      ),
    );
  }
}
