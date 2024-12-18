import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/comment_entity.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/comments/domain/repository/comment_reposirory.dart';

class GetCommentsUsecase implements UseCase<List<CommentEntity>, String> {
  final CommentRepository commentRepository;

  GetCommentsUsecase(this.commentRepository);

  @override
  Future<Either<Failure, List<CommentEntity>>> call(String postId) async {
    return await commentRepository.getComments(postId);
  }
}