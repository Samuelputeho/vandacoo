import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecases/usecase.dart';
import '../repository/global_comments_repo.dart';

class GetViewedStoriesUseCase implements UseCase<List<String>, String> {
  final GlobalCommentsRepository repository;

  GetViewedStoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(String userId) async {
    return await repository.getViewedStories(userId);
  }
}
