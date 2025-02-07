import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/messages/domain/repository/message_repository.dart';

class MarkMessageReadParams {
  final String messageId;

  MarkMessageReadParams({
    required this.messageId,
  });
}

class MarkMessageReadUsecase implements UseCase<Unit, MarkMessageReadParams> {
  final MessageRepository repository;

  MarkMessageReadUsecase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(MarkMessageReadParams params) async {
    return await repository.markMessageAsRead(
      messageId: params.messageId,
    );
  }
}
