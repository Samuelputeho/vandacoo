import 'package:fpdart/fpdart.dart';

import '../../../../error/failure.dart';
import '../../../../usecases/usecase.dart';
import '../../../entities/comment_entity.dart';
import '../repository/global_comments_repo.dart';

class GlobalCommentsGetCommentUsecase
    implements UseCase<List<CommentEntity>, String> {
  final GlobalCommentsRepository repository;

  GlobalCommentsGetCommentUsecase(this.repository);

  @override
  Future<Either<Failure, List<CommentEntity>>> call(String params) {
    return repository.getComments(params);
  }
}
