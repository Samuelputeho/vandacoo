import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import '../repository/global_comments_repo.dart';

class GlobalReportPostParams {
  final String postId;
  final String reporterId;
  final String reason;
  final String? description;

  GlobalReportPostParams({
    required this.postId,
    required this.reporterId,
    required this.reason,
    this.description,
  });
}

class GlobalReportPostUseCase implements UseCase<void, GlobalReportPostParams> {
  final GlobalCommentsRepository repository;

  GlobalReportPostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(GlobalReportPostParams params) async {
    return await repository.reportPost(
      postId: params.postId,
      reporterId: params.reporterId,
      reason: params.reason,
      description: params.description,
    );
  }
}
