import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repository/profile_repository.dart';

class GetPosterForUserUsecase implements UseCase<List<PostEntity>, String> {
  final ProfileRepository profileRepository;

  GetPosterForUserUsecase({required this.profileRepository});

  @override
  Future<Either<Failure, List<PostEntity>>> call(String userId) async {
    try {
      final posts = await profileRepository.getPostsForUser(userId);
      return posts;
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}

class GetPostForUserParams {
  final String userId;

  GetPostForUserParams({required this.userId});
}
