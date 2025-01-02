import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/messages/domain/entity/message_entity.dart';
import 'package:vandacoo/features/messages/domain/repository/message_repository.dart';

class GetMessagesParams {
  final String senderId;
  final String receiverId;

  GetMessagesParams({
    required this.senderId,
    required this.receiverId,
  });
}

class GetMessagesUsecase
    implements UseCase<List<MessageEntity>, GetMessagesParams> {
  final MessageRepository repository;

  GetMessagesUsecase(this.repository);

  @override
  Future<Either<Failure, List<MessageEntity>>> call(
      GetMessagesParams params) async {
    return await repository.getMessages(
      senderId: params.senderId,
      receiverId: params.receiverId,
    );
  }
}
