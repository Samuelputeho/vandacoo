import 'package:fpdart/fpdart.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repository/global_comments_repo.dart';

class GlobalDeletePostUseCase implements UseCase<void, String> {
  final GlobalCommentsRepository repository;

  GlobalDeletePostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String postId) async {
    return await repository.deletePost(postId);
  }
}
