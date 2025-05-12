import 'package:fpdart/fpdart.dart';

import '../../../../error/failure.dart';
import '../../../../usecase/usecase.dart';
import '../repository/global_comments_repo.dart';

class GlobalToggleBookmarkUseCase
    implements UseCase<void, GlobalToggleBookmarkParams> {
  final GlobalCommentsRepository repository;

  GlobalToggleBookmarkUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(GlobalToggleBookmarkParams params) async {
    return repository.toggleBookmark(
      params.postId,
    );
  }
}

class GlobalToggleBookmarkParams {
  final String postId;

  GlobalToggleBookmarkParams({
    required this.postId,
  });
}
