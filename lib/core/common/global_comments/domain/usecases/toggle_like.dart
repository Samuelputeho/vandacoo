import 'package:fpdart/fpdart.dart';

import '../../../../error/failure.dart';
import '../../../../usecase/usecase.dart';
import '../repository/global_comments_repo.dart';

class GlobalToggleLikeParams {
  final String postId;
  final String userId;

  GlobalToggleLikeParams({
    required this.postId,
    required this.userId,
  });
}

class GlobalToggleLikeUsecase implements UseCase<void, GlobalToggleLikeParams> {
  final GlobalCommentsRepository globalCommentsRepository;

  GlobalToggleLikeUsecase({required this.globalCommentsRepository});

  @override
  Future<Either<Failure, void>> call(GlobalToggleLikeParams params) async {
    return await globalCommentsRepository.toggleLike(
      postId: params.postId,
      userId: params.userId,
    );
  }
}
