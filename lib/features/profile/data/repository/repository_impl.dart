import '../../../../core/common/models/post_model.dart';
import '../../domain/repository/profile_repository.dart';
import '../datasource/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource remoteDatasource;

  ProfileRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<PostModel>> getPostsForUser(String userId) async {
    return remoteDatasource.getPostsForUser(userId);
  }
}
