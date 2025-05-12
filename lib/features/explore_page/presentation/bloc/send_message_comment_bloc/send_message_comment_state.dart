part of 'send_message_comment_bloc.dart';

sealed class SendMessageCommentState extends Equatable {
  const SendMessageCommentState();

  @override
  List<Object?> get props => [];
}

class SendMessageCommentInitial extends SendMessageCommentState {}

class SendMessageCommentLoading extends SendMessageCommentState {}

class SendMessageCommentSuccess extends SendMessageCommentState {
  final MessageEntity message;

  const SendMessageCommentSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SendMessageCommentFailure extends SendMessageCommentState {
  final String error;

  const SendMessageCommentFailure(this.error);

  @override
  List<Object?> get props => [error];
}
