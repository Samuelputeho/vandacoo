part of 'send_message_comment_bloc.dart';

sealed class SendMessageCommentEvent extends Equatable {
  const SendMessageCommentEvent();

  @override
  List<Object?> get props => [];
}

class SendMessageCommentRequestEvent extends SendMessageCommentEvent {
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final File? mediaFile;
  final String? mediaUrl;

  const SendMessageCommentRequestEvent({
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = MessageType.text,
    this.mediaFile,
    this.mediaUrl,
  });

  @override
  List<Object?> get props =>
      [senderId, receiverId, content, messageType, mediaFile, mediaUrl];
}
