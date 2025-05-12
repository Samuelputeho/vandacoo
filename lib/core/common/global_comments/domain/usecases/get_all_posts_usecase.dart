import 'package:fpdart/fpdart.dart';

import '../../../../error/failure.dart';
import '../../../../usecases/usecase.dart';
import '../../../entities/post_entity.dart';
import '../repository/global_comments_repo.dart';

class BookMarkGetAllPostsUsecase implements UseCase<List<PostEntity>, String> {
  final GlobalCommentsRepository globalCommentsRepository;

  BookMarkGetAllPostsUsecase(this.globalCommentsRepository);

  @override
  Future<Either<Failure, List<PostEntity>>> call(String userId) async {
    return await globalCommentsRepository.getAllPosts(userId);
  }
}
