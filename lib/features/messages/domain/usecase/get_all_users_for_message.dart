import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/messages/domain/repository/message_repository.dart';

class GetAllUsersForMessageUseCase
    implements UseCase<List<UserEntity>, NoParams> {
  final MessageRepository messageRepository;

  GetAllUsersForMessageUseCase(this.messageRepository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(NoParams params) async {
    return await messageRepository.getAllUsers();
  }
}
