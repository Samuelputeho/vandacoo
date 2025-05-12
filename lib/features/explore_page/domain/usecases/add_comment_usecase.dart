import 'package:fpdart/fpdart.dart';

import '../../../../core/common/entities/comment_entity.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/post_repository.dart';

class AddCommentUseCase implements UseCase<CommentEntity, AddCommentParams> {
  final PostRepository postRepository;

  AddCommentUseCase(this.postRepository);

  @override
  Future<Either<Failure, CommentEntity>> call(AddCommentParams params) async {
    return await postRepository.addComment(
      params.posterId,
      params.userId,
      params.comment,
    );
  }
}

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
