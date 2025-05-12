class MessageEntity {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? mediaUrl;
  final MessageType messageType;

  MessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.readAt,
    this.mediaUrl,
    this.messageType = MessageType.text,
  });
}

enum MessageType { text, image, video }
