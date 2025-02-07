import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/common/models/post_model.dart';
import 'package:vandacoo/core/constants/app_consts.dart';
import 'package:vandacoo/core/error/exceptions.dart';

import '../../../../core/common/models/comment_model.dart';
import '../../../../core/common/models/story_model.dart';

abstract interface class PostRemoteDataSource {
//funcions for the comments

//delete comment
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  });

  Future<List<CommentModel>> getComments(String posterId);
  Future<CommentModel> addComment(
      String posterId, String userId, String comment);

  // get all comments
  Future<List<CommentModel>> getAllComments();

//functions for the posts
  //I do not know what this is for
  Future<PostModel> uploadPost(PostModel post);

  //I do not know what this is for
  Future<String> uploadImage({
    required File image,
    required PostModel post,
  });
  Future<List<PostModel>> getAllPosts(String userId);
  Future<void> markStoryAsViewed(String storyId, String viewerId);
  Future<List<StoryModel>> getViewedStories(String viewerId);
  Future<void> deletePost(String postId);
  // Update post caption
  Future<void> updatePostCaption({
    required String postId,
    required String caption,
  });

  Future<void> toggleBookmark({
    required String postId,
    required String userId,
  });
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final SupabaseClient supabaseClient;

  PostRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<PostModel> uploadPost(PostModel post) async {
    try {
      final postData = await supabaseClient
          .from(AppConstants.postTable)
          .insert(post.toJson())
          .select();

      return PostModel.fromJson(postData.first);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadImage({
    required File image,
    required PostModel post,
  }) async {
    try {
      await supabaseClient.storage
          .from(AppConstants.postImagesBucket)
          .upload(post.id, image);

      return supabaseClient.storage
          .from(AppConstants.postImagesBucket)
          .getPublicUrl(post.id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PostModel>> getAllPosts(String userId) async {
    try {
      final posts = await supabaseClient
          .from(AppConstants.postTable)
          .select('''
            *,
            profiles!posts_user_id_fkey (
              name,
              propic
            ),
            bookmarks!left (
              user_id
            )
          ''')
          .eq('status', 'active')
          .eq('bookmarks.user_id', userId)
          .order('created_at', ascending: false);

      return posts.map((post) {
        final profileData = post['profiles'] as Map<String, dynamic>;
        String? proPic = profileData['propic'] as String?;
        // Clean the URL by removing whitespace and newlines
        if (proPic != null) {
          proPic = proPic.trim().replaceAll(RegExp(r'\s+'), '');
        }

        final bookmarks = post['bookmarks'] as List<dynamic>;
        final isBookmarked = bookmarks.isNotEmpty;

        return PostModel.fromJson(post).copyWith(
          posterName: profileData['name'] as String?,
          posterProPic: proPic,
          isBookmarked: isBookmarked,
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markStoryAsViewed(String storyId, String viewerId) async {
    try {
      await supabaseClient.from(AppConstants.storyViewsTable).upsert(
        {
          'story_id': storyId,
          'viewer_id': viewerId,
          'viewed_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'story_id,viewer_id',
      );
    } on PostgrestException catch (e) {
      // Ignore duplicate key violations as they mean the story is already viewed
      if (e.code != '23505') {
        throw ServerException(e.message);
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<StoryModel>> getViewedStories(String viewerId) async {
    try {
      final response = await supabaseClient
          .from(AppConstants.storyViewsTable)
          .select('story_id')
          .eq('viewer_id', viewerId);

      return (response as List)
          .map((item) => StoryModel.fromJson(item))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await supabaseClient
          .from(AppConstants.postTable)
          .delete()
          .eq('id', postId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updatePostCaption({
    required String postId,
    required String caption,
  }) async {
    try {
      await supabaseClient.from(AppConstants.postTable).update({
        'caption': caption,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', postId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

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
  Future<void> toggleBookmark({
    required String postId,
    required String userId,
  }) async {
    try {
      // Check if bookmark exists
      final existingBookmark = await supabaseClient
          .from(AppConstants.bookmarksTable)
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingBookmark == null) {
        // Add bookmark
        await supabaseClient.from(AppConstants.bookmarksTable).insert({
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Remove bookmark
        await supabaseClient
            .from(AppConstants.bookmarksTable)
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      }
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
      //print
      print(e.message);
      throw ServerException(e.message);
    } catch (e) {
      //print
      print(e.toString());
      throw ServerException(e.toString());
    }
  }
}
