part of 'message_bloc.dart';

@immutable
abstract class MessageEvent {}

class SendMessageEvent extends MessageEvent {
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final File? mediaFile;

  SendMessageEvent({
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = MessageType.text,
    this.mediaFile,
  });
}

class FetchMessagesEvent extends MessageEvent {
  final String senderId;
  final String? receiverId;

  FetchMessagesEvent({
    required this.senderId,
    this.receiverId,
  });
}

class FetchAllMessagesEvent extends MessageEvent {
  final String userId;

  FetchAllMessagesEvent({
    required this.userId,
  });
}

class DeleteMessageThreadEvent extends MessageEvent {
  final String userId;
  final String otherUserId;

  DeleteMessageThreadEvent({
    required this.userId,
    required this.otherUserId,
  });
}

class MarkMessageAsReadEvent extends MessageEvent {
  final String messageId;

  MarkMessageAsReadEvent({
    required this.messageId,
  });
}

class FetchAllUsersEvent extends MessageEvent {}

class DeleteMessageEvent extends MessageEvent {
  final String messageId;
  final String userId;

  DeleteMessageEvent({
    required this.messageId,
    required this.userId,
  });
}
