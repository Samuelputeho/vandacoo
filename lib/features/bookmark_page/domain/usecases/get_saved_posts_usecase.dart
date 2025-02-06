import 'package:dartz/dartz.dart';
import 'package:vandacoo/core/error/failures.dart';
import 'package:vandacoo/core/usecases/usecase.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/features/bookmark_page/domain/repository/saved_posts_repository.dart';

class GetSavedPostsUseCase implements UseCase<List<PostEntity>, NoParams> {
  final SavedPostsRepository repository;

  GetSavedPostsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PostEntity>>> call(NoParams params) async {
    return await repository.getSavedPosts();
  }
}
