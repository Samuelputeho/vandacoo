part of 'message_bloc.dart';

@immutable
abstract class MessageEvent {}

class SendMessageEvent extends MessageEvent {
  final String senderId;
  final String receiverId;
  final String content;

  SendMessageEvent({
    required this.senderId,
    required this.receiverId,
    required this.content,
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