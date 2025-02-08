import 'package:fpdart/fpdart.dart';

import '../../../../error/failure.dart';
import '../../../../usecases/usecase.dart';
import '../../../entities/comment_entity.dart';
import '../repository/global_comments_repo.dart';

class GlobalCommentsAddCommentUseCase
    implements UseCase<CommentEntity, GlobalCommentsAddCommentParams> {
  final GlobalCommentsRepository repository;

  GlobalCommentsAddCommentUseCase(this.repository);

  @override
  Future<Either<Failure, CommentEntity>> call(
      GlobalCommentsAddCommentParams params) async {
    return await repository.addComment(
      params.posterId,
      params.userId,
      params.comment,
    );
  }
}

class GlobalCommentsAddCommentParams {
  final String posterId;
  final String userId;
  final String comment;

  GlobalCommentsAddCommentParams({
    required this.posterId,
    required this.userId,
    required this.comment,
  });
}
