import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/common/entities/message_entity.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failure.dart';
import '../../../../features/explore_page/domain/repository/post_repository.dart';

class SendMessageUseCaseParams {
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final File? mediaFile;
  final String? mediaUrl;

  SendMessageUseCaseParams({
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = MessageType.text,
    this.mediaFile,
    this.mediaUrl,
  });
}

class SendMessage implements UseCase<MessageEntity, SendMessageUseCaseParams> {
  final PostRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, MessageEntity>> call(
      SendMessageUseCaseParams params) async {
    return await repository.sendMessage(
      senderId: params.senderId,
      receiverId: params.receiverId,
      content: params.content,
      messageType: params.messageType,
      mediaFile: params.mediaFile,
      mediaUrl: params.mediaUrl,
    );
  }
}
