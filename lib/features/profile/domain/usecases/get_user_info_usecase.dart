import 'package:fpdart/fpdart.dart';

import '../../../../core/common/entities/user_entity.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/profile_repository.dart';

class GetUserInfoUsecase implements UseCase<UserEntity, GetUserInfoParams> {
  final ProfileRepository profileRepository;

  GetUserInfoUsecase({required this.profileRepository});

  @override
  Future<Either<Failure, UserEntity>> call(GetUserInfoParams params) async {
    return profileRepository.getUserInformation(params.userId);
  }
}

class GetUserInfoParams {
  final String userId;

  GetUserInfoParams({required this.userId});
}
