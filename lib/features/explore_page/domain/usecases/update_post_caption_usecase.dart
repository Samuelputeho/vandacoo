import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/post_repository.dart';

class UpdatePostCaptionUseCase
    implements UseCase<void, UpdatePostCaptionParams> {
  final PostRepository repository;

  UpdatePostCaptionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePostCaptionParams params) async {
    return repository.updatePostCaption(
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
