import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecases/usecase.dart';
import '../repository/global_comments_repo.dart';

class GlobalCommentsUpdatePostCaptionUseCase
    implements UseCase<void, UpdatePostCaptionParams> {
  final GlobalCommentsRepository repository;

  GlobalCommentsUpdatePostCaptionUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(UpdatePostCaptionParams params) async {
    return await repository.updatePostCaption(
      postId: params.postId,
      caption: params.caption,
    );
  }
}

class UpdatePostCaptionParams {
  final String postId;
  final String caption;

  UpdatePostCaptionParams({
    required this.postId,
    required this.caption,
  });
}
