import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/comment_entity.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/comments/domain/repository/comment_reposirory.dart';

class AddCommentParams {
  final String posterId;
  final String userId;
  final String comment;

  AddCommentParams({
    required this.posterId,
    required this.userId,
    required this.comment,
  });
}

class AddCommentUsecase implements UseCase<CommentEntity, AddCommentParams> {
  final CommentRepository commentRepository;

  AddCommentUsecase(this.commentRepository);

  @override
  Future<Either<Failure, CommentEntity>> call(AddCommentParams params) async {
    return await commentRepository.addComment(
      params.posterId,
      params.userId,
      params.comment,
    );
  }
}
