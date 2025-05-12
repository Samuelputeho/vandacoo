import 'package:fpdart/fpdart.dart';

import '../../../../core/common/entities/user_entity.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/post_repository.dart';

class GetCurrentUserInformationUsecase
    implements UseCase<UserEntity, GetCurrentUserInformationUsecaseParams> {
  final PostRepository repository;

  GetCurrentUserInformationUsecase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(
      GetCurrentUserInformationUsecaseParams params) async {
    return repository.getCurrentUserInformation(params.userId);
  }
}

class GetCurrentUserInformationUsecaseParams {
  final String userId;

  GetCurrentUserInformationUsecaseParams({required this.userId});
}
