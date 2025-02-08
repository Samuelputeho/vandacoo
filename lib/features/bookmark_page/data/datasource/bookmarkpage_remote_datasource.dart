import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class BookmarkPageRemoteDataSource {
  Future<void> toggleBookmark(String postId);
  Future<List<String>> getBookmarkedPosts();
}

class BookmarkPageRemoteDataSourceImpl implements BookmarkPageRemoteDataSource {
  final SupabaseClient _supabase;

  BookmarkPageRemoteDataSourceImpl(this._supabase);

  @override
  Future<void> toggleBookmark(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final bookmarkRef = _supabase
        .from('bookmarks')
        .select('id')
        .eq('user_id', userId)
        .eq('post_id', postId)
        .single();

    // ignore: unnecessary_null_comparison
    final exists = await bookmarkRef != null;
    if (exists) {
      await _supabase
          .from('bookmarks')
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);
    } else {
      await _supabase.from('bookmarks').insert({
        'user_id': userId,
        'post_id': postId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<List<String>> getBookmarkedPosts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('bookmarks')
        .select('post_id')
        .eq('user_id', userId);

    return (response as List)
        .map((bookmark) => bookmark['post_id'] as String)
        .toList();
  }
}
