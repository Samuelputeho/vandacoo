import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/all_posts/domain/repository/post_repository.dart';

class MarkStoryViewedParams {
  final String storyId;
  final String viewerId;

  MarkStoryViewedParams({
    required this.storyId,
    required this.viewerId,
  });
}

class MarkStoryViewedUsecase implements UseCase<void, MarkStoryViewedParams> {
  final PostRepository repository;

  MarkStoryViewedUsecase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkStoryViewedParams params) {
    return repository.markStoryAsViewed(params.storyId, params.viewerId);
  }
}
