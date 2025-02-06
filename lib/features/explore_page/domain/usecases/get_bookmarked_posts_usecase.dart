import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/explore_page/domain/repository/bookmark_repository.dart';

class GetBookmarkedPostsUseCase implements UseCase<List<String>, NoParams> {
  final BookmarkRepository repository;

  GetBookmarkedPostsUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    try {
      final posts = await repository.getBookmarkedPosts();
      return Right(posts);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
