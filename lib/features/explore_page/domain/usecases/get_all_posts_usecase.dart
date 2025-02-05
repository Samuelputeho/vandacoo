import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/explore_page/domain/repository/post_repository.dart';

class GetAllPostsUsecase implements UseCase<List<PostEntity>, NoParams> {
  final PostRepository postRepository;

  GetAllPostsUsecase(this.postRepository);

  @override
  Future<Either<Failure, List<PostEntity>>> call(NoParams params) async {
    return await postRepository.getAllPosts();
  }
}
