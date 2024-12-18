import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/error/exceptions.dart';

abstract interface class LikeRemoteDataSource {
  Future<void> toggleLike(String postId, String userId);
  Future<List<String>> getLikes(String postId);
}

class LikeRemoteDataSourceImpl implements LikeRemoteDataSource {
  final SupabaseClient supabaseClient;

  LikeRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<void> toggleLike(String postId, String userId) async {
    try {
      // Check if like exists
      final existingLike = await supabaseClient
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike: Remove the like if it exists
        await supabaseClient
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        // Like: Add new like
        await supabaseClient.from('likes').insert({
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error in toggleLike: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<String>> getLikes(String postId) async {
    try {
      final response = await supabaseClient
          .from('likes')
          .select('user_id')
          .eq('post_id', postId);

      return (response as List)
          .map((like) => like['user_id'] as String)
          .toList();
    } catch (e) {
      print('Error in getLikes: $e');
      throw ServerException(e.toString());
    }
  }

  // Optional: Get like count for a post
  Future<int> getLikeCount(String postId) async {
    try {
      final response = await supabaseClient
          .from('likes')
          .select('*')
          .eq('post_id', postId);

      return (response as List).length;
    } catch (e) {
      print('Error in getLikeCount: $e');
      throw ServerException(e.toString());
    }
  }
}