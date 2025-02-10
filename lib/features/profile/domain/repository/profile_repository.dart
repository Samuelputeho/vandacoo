import 'package:vandacoo/core/common/entities/post_entity.dart';

abstract interface class ProfileRepository {
  Future<List<PostEntity>> getPostsForUser(String userId);
}
