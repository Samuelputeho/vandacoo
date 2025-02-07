part of 'message_bloc.dart';

@immutable
abstract class MessageState {}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessageLoaded extends MessageState {
  final List<MessageEntity> messages;

  MessageLoaded(this.messages);
}

class MessageSent extends MessageState {
  final MessageEntity message;

  MessageSent(this.message);
}

class MessageThreadDeleted extends MessageState {}

class MessageMarkedAsRead extends MessageState {}

class UsersLoaded extends MessageState {
  final List<UserEntity> users;

  UsersLoaded(this.users);
}

class MessageFailure extends MessageState {
  final String message;

  MessageFailure(this.message);
}

class MessageDeleted extends MessageState {
  final String messageId;

  MessageDeleted(this.messageId);
}
