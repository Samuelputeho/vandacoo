import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/messages/domain/repository/message_repository.dart';

class DeleteMessageParams {
  final String messageId;
  final String userId;

  DeleteMessageParams({
    required this.messageId,
    required this.userId,
  });
}

class DeleteMessageUsecase implements UseCase<Unit, DeleteMessageParams> {
  final MessageRepository repository;

  DeleteMessageUsecase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteMessageParams params) async {
    return await repository.deleteMessage(
      messageId: params.messageId,
      userId: params.userId,
    );
  }
}
