import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/core/common/entities/message_entity.dart';
import 'package:vandacoo/features/messages/domain/repository/message_repository.dart';

class SendMessageParams {
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final File? mediaFile;

  SendMessageParams({
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = MessageType.text,
    this.mediaFile,
  });
}

class SendMessageUsecase implements UseCase<MessageEntity, SendMessageParams> {
  final MessageRepository repository;

  SendMessageUsecase(this.repository);

  @override
  Future<Either<Failure, MessageEntity>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      senderId: params.senderId,
      receiverId: params.receiverId,
      content: params.content,
      messageType: params.messageType,
      mediaFile: params.mediaFile,
    );
  }
}
