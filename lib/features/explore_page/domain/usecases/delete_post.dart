import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/post_repository.dart';

class DeletePostUseCase implements UseCase<void, DeletePostParams> {
  final PostRepository postRepository;

  DeletePostUseCase(this.postRepository);

  @override
  Future<Either<Failure, void>> call(DeletePostParams params) async {
    return postRepository.deletePost(params.postId);
  }
}

class DeletePostParams {
  final String postId;

  DeletePostParams(this.postId);
}
