import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';

abstract class LikeRepository {
  Future<Either<Failure, void>> toggleLike(String postId, String userId);
  Future<Either<Failure, List<String>>> getLikes(String postId);
}