import 'package:dartz/dartz.dart';
import 'package:vandacoo/core/error/failures.dart';
import 'package:vandacoo/core/usecases/usecase.dart';
import 'package:vandacoo/features/bookmark_page/domain/repository/saved_posts_repository.dart';

class ToggleSavedPostUseCase implements UseCase<void, ToggleSavedPostParams> {
  final SavedPostsRepository repository;

  ToggleSavedPostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ToggleSavedPostParams params) async {
    return await repository.toggleSavedPost(params.postId);
  }
}

class ToggleSavedPostParams {
  final String postId;

  ToggleSavedPostParams({required this.postId});
}
