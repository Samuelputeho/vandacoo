part of 'message_bloc.dart';

@immutable
abstract class MessageState {}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessageLoaded extends MessageState {
  final List<MessageEntity> messages;

  MessageLoaded(this.messages);
}

class MessageFailure extends MessageState {
  final String message;

  MessageFailure(this.message);
}