import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/common/models/comment_model.dart';
import 'package:vandacoo/core/error/exceptions.dart';

abstract interface class CommentRemoteDataSource {
  Future<List<CommentModel>> getComments(String posterId);
  Future<CommentModel> addComment(String posterId, String userId, String comment);
}

class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  final SupabaseClient supabaseClient;

  CommentRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<CommentModel>> getComments(String posterId) async {
    try {
      print('Fetching comments for posterId: $posterId');

      final comments = await supabaseClient
          .from('comments')
          .select('''
            *,
            profiles (
              name,
              propic
            )
          ''')
          .eq('posterId', posterId)
          .order('createdAt');

      print('Raw comments data: $comments');

      return comments.map((comment) => CommentModel.fromJson(comment).copyWith(
        userName: comment['profiles']['name'],
        userProPic: comment['profiles']['propic'],
      )).toList();
    } on PostgrestException catch (e) {
      print('PostgrestException: ${e.message}');
      throw ServerException(e.message);
    } catch (e, stackTrace) {
      print('Error in getComments: $e');
      print('Stack trace: $stackTrace');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CommentModel> addComment(String posterId, String userId, String comment) async {
    try {
      print('Adding comment with posterId: $posterId, userId: $userId');
      
      final commentData = await supabaseClient
          .from('comments')
          .insert({
            'posterId': posterId,
            'userId': userId,
            'comment': comment,
            'createdAt': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            profiles (
              name,
              propic
            )
          ''')
          .single();

      print('Comment added successfully: $commentData');
      
      return CommentModel.fromJson(commentData).copyWith(
        userName: commentData['profiles']['name'],
        userProPic: commentData['profiles']['propic'],
      );
      
    } catch (e, stackTrace) {
      print('Error in addComment: $e');
      print('Stack trace: $stackTrace');
      throw ServerException(e.toString());
    }
  }
}
