import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/post_repository.dart';

class ToggleBookmarkUseCase implements UseCase<void, ToggleBookmarkParams> {
  final PostRepository repository;

  ToggleBookmarkUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ToggleBookmarkParams params) async {
    return repository.toggleBookmark(
      postId: params.postId,
      userId: params.userId,
    );
  }
}

class ToggleBookmarkParams {
  final String postId;
  final String userId;

  ToggleBookmarkParams({
    required this.postId,
    required this.userId,
  });
}
