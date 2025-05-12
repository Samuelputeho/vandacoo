import 'package:fpdart/fpdart.dart';

import '../../../../core/common/entities/comment_entity.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/post_repository.dart';

class GetAllCommentsUseCase implements UseCase<List<CommentEntity>, NoParams> {
  final PostRepository repository;

  GetAllCommentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CommentEntity>>> call(NoParams params) async =>
      repository.getAllComments();
}
