// ignore: implementation_imports
import 'package:fpdart/src/either.dart';

import 'package:vandacoo/core/error/failure.dart';

import '../../../../usecases/usecase.dart';
import '../../../entities/comment_entity.dart';
import '../repository/global_comments_repo.dart';

class GlobalCommentsGetAllCommentsUsecase
    implements UseCase<List<CommentEntity>, NoParams> {
  final GlobalCommentsRepository repository;

  GlobalCommentsGetAllCommentsUsecase({required this.repository});

  @override
  Future<Either<Failure, List<CommentEntity>>> call(NoParams params) {
    return repository.getAllComments();
  }
}
