import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/common/models/comment_model.dart';
import 'package:vandacoo/core/error/exceptions.dart';

import '../../../../core/constants/app_consts.dart';

abstract interface class CommentRemoteDataSource {
  Future<List<CommentModel>> getComments(String posterId);
  Future<CommentModel> addComment(
      String posterId, String userId, String comment);

  // get all comments
  Future<List<CommentModel>> getAllComments();
}

class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  final SupabaseClient supabaseClient;

  CommentRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<CommentModel>> getComments(String posterId) async {
    try {
      print('Fetching comments for posterId: $posterId');

      final comments = await supabaseClient.from('comments').select('''
            *,
            profiles (
              name,
              propic
            )
          ''').eq('posterId', posterId).order('createdAt');

      print('Raw comments data: $comments');

      return comments
          .map((comment) => CommentModel.fromJson(comment).copyWith(
                userName: comment['profiles']['name'],
                userProPic: comment['profiles']['propic'],
              ))
          .toList();
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
  Future<CommentModel> addComment(
      String posterId, String userId, String comment) async {
    try {
      print('Adding comment with posterId: $posterId, userId: $userId');
      final now = DateTime.now();
      print('Current time when adding comment: $now');

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

      print('Comment added successfully: $commentData');
      print('Comment createdAt from DB: ${commentData['createdAt']}');
      print('Parsed as DateTime: ${DateTime.parse(commentData['createdAt'])}');

      final commentModel = CommentModel.fromJson(commentData).copyWith(
        userName: commentData['profiles']['name'],
        userProPic: commentData['profiles']['propic'],
      );

      print('Final comment DateTime in model: ${commentModel.createdAt}');
      return commentModel;
    } catch (e, stackTrace) {
      print('Error in addComment: $e');
      print('Stack trace: $stackTrace');
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
}
