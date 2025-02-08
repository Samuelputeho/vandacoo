import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/app_consts.dart';
import '../../../../error/exceptions.dart';
import '../../../models/comment_model.dart';

abstract interface class GlobalCommentsRemoteDatasource {
//delete comment
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  });
// read comment
  Future<List<CommentModel>> getComments(String posterId);
// add comment
  Future<CommentModel> addComment(
      String posterId, String userId, String comment);

  // get all comments
  // read all comments
  Future<List<CommentModel>> getAllComments();
}

class GlobalCommentsRemoteDatasourceImpl
    implements GlobalCommentsRemoteDatasource {
  final SupabaseClient supabaseClient;

  GlobalCommentsRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<CommentModel> addComment(
    String posterId,
    String userId,
    String comment,
  ) async {
    try {
      final now = DateTime.now();

      final commentData = await supabaseClient.from('comments').insert({
        'posterId': posterId,
        'userId': userId,
        'comment': comment,
        'createdAt': now.toIso8601String(),
      }).select('''
            *,
            profiles (
              name,
              propic
            )
          ''').single();

      final commentModel = CommentModel.fromJson(commentData).copyWith(
        userName: commentData['profiles']['name'],
        userProPic: commentData['profiles']['propic'],
      );

      return commentModel;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CommentModel>> getAllComments() async {
    try {
      final comments =
          await supabaseClient.from(AppConstants.commentsTable).select('''
        *,
        profiles (
          name,
          propic
        )
      ''').order('createdAt');

      return comments
          .map((comment) => CommentModel.fromJson(comment).copyWith(
                userName: comment['profiles']['name'],
                userProPic: comment['profiles']['propic'],
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CommentModel>> getComments(String posterId) async {
    try {
      final comments = await supabaseClient.from('comments').select('''
            *,
            profiles (
              name,
              propic
            )
          ''').eq('posterId', posterId).order('createdAt');

      return comments
          .map((comment) => CommentModel.fromJson(comment).copyWith(
                userName: comment['profiles']['name'],
                userProPic: comment['profiles']['propic'],
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      await supabaseClient
          .from(AppConstants.commentsTable)
          .delete()
          .eq('id', commentId)
          .eq('userId', userId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
