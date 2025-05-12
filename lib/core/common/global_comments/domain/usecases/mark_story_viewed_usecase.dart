import 'package:fpdart/fpdart.dart';

import '../../../../error/failure.dart';
import '../../../../usecase/usecase.dart';
import '../repository/global_comments_repo.dart';

class MarkStoryViewedUseCase implements UseCase<void, MarkStoryViewedParams> {
  final GlobalCommentsRepository repository;

  MarkStoryViewedUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkStoryViewedParams params) async {
    return repository.markStoryAsViewed(
      storyId: params.storyId,
      userId: params.userId,
    );
  }
}

class MarkStoryViewedParams {
  final String storyId;
  final String userId;

  MarkStoryViewedParams({
    required this.storyId,
    required this.userId,
  });
}
