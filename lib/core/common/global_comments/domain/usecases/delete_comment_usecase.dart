import 'package:fpdart/fpdart.dart';

import '../../../../error/failure.dart';

import '../../../../usecases/usecase.dart';
import '../repository/global_comments_repo.dart';

class GlobalCommentsDeleteCommentUsecase
    implements UseCase<void, GlobalCommentsDeleteCommentParams> {
  final GlobalCommentsRepository repository;

  GlobalCommentsDeleteCommentUsecase({required this.repository});

  @override
  Future<Either<Failure, void>> call(
      GlobalCommentsDeleteCommentParams params) async {
    return repository.deleteComment(
      commentId: params.commentId,
      userId: params.userId,
    );
  }
}

class GlobalCommentsDeleteCommentParams {
  final String commentId;
  final String userId;

  GlobalCommentsDeleteCommentParams({
    required this.commentId,
    required this.userId,
  });
}
