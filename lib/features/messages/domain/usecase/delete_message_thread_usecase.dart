import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/messages/domain/repository/message_repository.dart';

class DeleteMessageThreadParams {
  final String userId;
  final String otherUserId;

  DeleteMessageThreadParams({
    required this.userId,
    required this.otherUserId,
  });
}

class DeleteMessageThreadUsecase
    implements UseCase<Unit, DeleteMessageThreadParams> {
  final MessageRepository repository;

  DeleteMessageThreadUsecase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteMessageThreadParams params) async {
    return await repository.deleteMessageThread(
      userId: params.userId,
      otherUserId: params.otherUserId,
    );
  }
}
