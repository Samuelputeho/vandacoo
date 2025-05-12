import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/post_repository.dart';

class DeleteCommentUseCase implements UseCase<void, DeleteCommentParams> {
  final PostRepository repository;

  DeleteCommentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCommentParams params) async {
    return repository.deleteComment(
      commentId: params.commentId,
      userId: params.userId,
    );
  }
}

class DeleteCommentParams {
  final String commentId;
  final String userId;

  DeleteCommentParams({
    required this.commentId,
    required this.userId,
  });
}
