import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repository/bookmarkpage_repository.dart';

class BookmarkPageToggleBookmarkUseCase
    implements UseCase<void, BookmarkPageToggleBookmarkParams> {
  final BookmarkPageRepository repository;

  BookmarkPageToggleBookmarkUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
      BookmarkPageToggleBookmarkParams params) async {
    return repository.toggleBookmark(
      params.postId,
    );
  }
}

class BookmarkPageToggleBookmarkParams {
  final String postId;

  BookmarkPageToggleBookmarkParams({
    required this.postId,
  });
}
