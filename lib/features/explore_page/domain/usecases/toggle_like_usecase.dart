import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/explore_page/domain/repository/post_repository.dart';

class ToggleLikeParams {
  final String postId;
  final String userId;

  ToggleLikeParams({
    required this.postId,
    required this.userId,
  });
}

class ToggleLikeUsecase implements UseCase<void, ToggleLikeParams> {
  final PostRepository postRepository;

  ToggleLikeUsecase({required this.postRepository});

  @override
  Future<Either<Failure, void>> call(ToggleLikeParams params) async {
    return await postRepository.toggleLike(
      postId: params.postId,
      userId: params.userId,
    );
  }
}
