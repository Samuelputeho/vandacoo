import 'package:fpdart/fpdart.dart';

import '../../../../core/common/entities/comment_entity.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/post_repository.dart';

class GetCommentsUsecase implements UseCase<List<CommentEntity>, String> {
  final PostRepository postRepository;

  GetCommentsUsecase(this.postRepository);

  @override
  Future<Either<Failure, List<CommentEntity>>> call(String postId) async {
    return await postRepository.getComments(postId);
  }
}
