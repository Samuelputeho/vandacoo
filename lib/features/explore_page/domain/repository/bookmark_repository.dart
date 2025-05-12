import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

abstract class BookmarkRepository {
  Future<Either<Failure, void>> toggleBookmark(String postId);
  Future<Either<Failure, List<String>>> getBookmarkedPosts();
}
