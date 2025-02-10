import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/common/models/post_model.dart';

import '../../../../core/error/exceptions.dart';

abstract interface class ProfileRemoteDatasource {
  Future<List<PostModel>> getPostsForUser(String userId);
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final SupabaseClient supabase;

  ProfileRemoteDatasourceImpl({required this.supabase});

  @override
  Future<List<PostModel>> getPostsForUser(String userId) async {
    try {
      final response =
          await supabase.from('posts').select('*').eq('user_id', userId);
      return response.map((json) => PostModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
