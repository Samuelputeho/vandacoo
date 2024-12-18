import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/screens/messages/domain/entity/message_entity.dart';
import 'package:vandacoo/screens/messages/domain/repository/message_repository.dart';

class SendMessageParams {
  final String senderId;
  final String receiverId;
  final String content;

  SendMessageParams({
    required this.senderId,
    required this.receiverId,
    required this.content,
  });
}

class SendMessageUsecase implements UseCase<MessageEntity, SendMessageParams> {
  final MessageRepository repository;

  SendMessageUsecase(this.repository);

  @override
  Future<Either<Failure, MessageEntity>> call(SendMessageParams params) async {
    final result = await repository.sendMessage(
      senderId: params.senderId,
      receiverId: params.receiverId,
      content: params.content,
    );
    
    return result.map((messages) => messages.first); // Convert List<MessageEntity> to MessageEntity
  }
}