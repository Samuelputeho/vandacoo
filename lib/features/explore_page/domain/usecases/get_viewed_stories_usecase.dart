import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/explore_page/domain/repository/post_repository.dart';

import '../../../../core/common/entities/story_entitiy.dart';
import '../../../../core/error/failure.dart';

class GetViewedStoriesUsecase
    implements UseCase<List<StoryEntity>, ViewedStoriesParams> {
  final PostRepository repository;

  GetViewedStoriesUsecase(this.repository);

  @override
  Future<Either<Failure, List<StoryEntity>>> call(ViewedStoriesParams params) {
    return repository.getViewedStories(params.userId);
  }
}

class ViewedStoriesParams {
  final String userId;

  ViewedStoriesParams({required this.userId});
}
