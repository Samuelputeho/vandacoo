import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

abstract interface class BookmarkPageRepository {
  Future<Either<Failure, void>> toggleBookmark(String postId);
  Future<Either<Failure, List<String>>> getBookmarkedPosts();
}
