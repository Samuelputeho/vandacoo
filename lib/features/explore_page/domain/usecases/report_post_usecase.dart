import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/explore_page/domain/repository/post_repository.dart';

class ReportPostParams {
  final String postId;
  final String reporterId;
  final String reason;
  final String? description;

  ReportPostParams({
    required this.postId,
    required this.reporterId,
    required this.reason,
    this.description,
  });
}

class ReportPostUseCase implements UseCase<void, ReportPostParams> {
  final PostRepository repository;

  ReportPostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ReportPostParams params) async {
    return await repository.reportPost(
      postId: params.postId,
      reporterId: params.reporterId,
      reason: params.reason,
      description: params.description,
    );
  }
}
