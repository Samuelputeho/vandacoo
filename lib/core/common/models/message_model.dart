import 'package:vandacoo/core/common/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  MessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.createdAt,
    super.readAt,
    super.mediaUrl,
    super.messageType = MessageType.text,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      mediaUrl: json['mediaUrl'] as String?,
      messageType: _parseMessageType(json['messageType'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'mediaUrl': mediaUrl,
      'messageType': messageType.toString().split('.').last,
    };
  }

  static MessageType _parseMessageType(String? type) {
    if (type == null) return MessageType.text;
    return MessageType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => MessageType.text,
    );
  }
}
