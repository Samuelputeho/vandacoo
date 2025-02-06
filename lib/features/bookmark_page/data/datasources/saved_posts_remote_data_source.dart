import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/common/models/post_model.dart';
import 'package:vandacoo/core/constants/app_consts.dart';

abstract class SavedPostsRemoteDataSource {
  Future<void> toggleSavedPost(String postId);
  Future<List<PostModel>> getSavedPosts();
}

class SavedPostsRemoteDataSourceImpl implements SavedPostsRemoteDataSource {
  final SupabaseClient _supabase;

  SavedPostsRemoteDataSourceImpl(this._supabase);

  @override
  Future<void> toggleSavedPost(String postId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final savedPostRef = await _supabase
          .from(AppConstants.bookmarksTable)
          .select()
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      final exists = savedPostRef != null;

      if (exists) {
        await _supabase
            .from(AppConstants.bookmarksTable)
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
      } else {
        await _supabase.from(AppConstants.bookmarksTable).insert({
          'user_id': userId,
          'post_id': postId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle saved post: $e');
    }
  }

  @override
  Future<List<PostModel>> getSavedPosts() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final posts = await _supabase.from(AppConstants.bookmarksTable).select('''
            post:${AppConstants.postTable}!inner (
              *,
              profile:${AppConstants.profilesTable}!inner (
                name,
                propic
              )
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return posts.map((bookmark) {
        final post = bookmark['post'];
        return PostModel.fromJson({
          ...post,
          'is_bookmarked': true,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get saved posts: $e');
    }
  }
}
