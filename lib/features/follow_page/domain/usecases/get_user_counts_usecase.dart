import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/follow_page/domain/entities/follow_entity.dart';
import 'package:vandacoo/features/follow_page/domain/repository/follow_page_repository.dart';

class GetUserCountsUsecase
    implements UseCase<FollowEntity, GetUserCountsParams> {
  final FollowPageRepository _repository;

  GetUserCountsUsecase(this._repository);

  @override
  Future<Either<Failure, FollowEntity>> call(GetUserCountsParams params) async {
    return await _repository.getUserCounts(params.userId);
  }
}

class GetUserCountsParams {
  final String userId;

  GetUserCountsParams({required this.userId});
}
