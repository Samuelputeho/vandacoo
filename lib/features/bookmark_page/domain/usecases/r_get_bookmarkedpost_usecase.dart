import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repository/bookmarkpage_repository.dart';

class BookMarkPageGetBookmarkedPostsUseCase
    implements UseCase<List<String>, NoParams> {
  final BookmarkPageRepository repository;

  BookMarkPageGetBookmarkedPostsUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    try {
      final posts = await repository.getBookmarkedPosts();
      return posts;
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
