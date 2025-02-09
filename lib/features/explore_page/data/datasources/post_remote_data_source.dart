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

  // Add these new methods for reporting
  Future<void> reportPost({
    required String postId,
    required String reporterId,
    required String reason,
    String? description,
  });

  Future<bool> hasUserReportedPost({
    required String postId,
    required String reporterId,
  });

  Future<void> toggleLike({
    required String postId,
    required String userId,
  });

  Future<int> getPostLikesCount(String postId);

  Future<bool> isPostLikedByUser({
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
      print('🔍 PostRemoteDataSource - Fetching all posts for userId: $userId');
      final posts = await supabaseClient.from(AppConstants.postTable).select('''
            *,
            profiles!posts_user_id_fkey (
              name,
              propic
            ),
            bookmarks!left (
              user_id
            ),
            likes!left (
              user_id
            ),
            likes_count:likes(count)
          ''').eq('status', 'active').order('created_at', ascending: false);

      print(
          '📦 PostRemoteDataSource - Raw posts from database: ${posts.length}');
      print('🔄 PostRemoteDataSource - Starting to map posts...');

      final mappedPosts = posts.map((post) {
        final profileData = post['profiles'] as Map<String, dynamic>;
        print(
            '👤 PostRemoteDataSource - Processing post ID: ${post['id']} with type: ${post['post_type']}');

        String? proPic = profileData['propic'] as String?;
        if (proPic != null) {
          proPic = proPic.trim().replaceAll(RegExp(r'\s+'), '');
        }

        final bookmarks = post['bookmarks'] as List<dynamic>;
        final isBookmarked =
            bookmarks.any((bookmark) => bookmark['user_id'] == userId);

        final likes = post['likes'] as List<dynamic>;
        final isLiked = likes.isNotEmpty;
        final isPostLikedByUser =
            likes.any((like) => like['user_id'] == userId);

        int likesCount;
        try {
          if (post['likes_count'] is List) {
            final likesCountList = post['likes_count'] as List<dynamic>;
            likesCount = likesCountList.isNotEmpty
                ? (likesCountList[0]['count'] as int?) ?? 0
                : 0;
          } else {
            likesCount = (post['likes_count'] as int?) ?? 0;
          }
        } catch (e) {
          print(
              '⚠️ PostRemoteDataSource - Error processing likes count for post ${post['id']}: $e');
          likesCount = 0;
        }

        return PostModel.fromJson(post).copyWith(
          posterName: profileData['name'] as String?,
          posterProPic: proPic,
          isBookmarked: isBookmarked,
          isLiked: isLiked,
          likesCount: likesCount,
          isPostLikedByUser: isPostLikedByUser,
        );
      }).toList();

      print(
          '✅ PostRemoteDataSource - Successfully mapped ${mappedPosts.length} posts');
      return mappedPosts;
    } on PostgrestException catch (e) {
      print('❌ PostRemoteDataSource - PostgrestException: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      print('❌ PostRemoteDataSource - Error: $e');
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
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> reportPost({
    required String postId,
    required String reporterId,
    required String reason,
    String? description,
  }) async {
    try {
      // First check if user has already reported this post
      final hasReported = await hasUserReportedPost(
        postId: postId,
        reporterId: reporterId,
      );

      if (hasReported) {
        throw ServerException('You have already reported this post');
      }

      // Insert the report
      await supabaseClient.from('reports').insert({
        'post_id': postId,
        'reporter_id': reporterId,
        'reason': reason,
        'description': description,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> hasUserReportedPost({
    required String postId,
    required String reporterId,
  }) async {
    try {
      final response = await supabaseClient
          .from('reports')
          .select()
          .eq('post_id', postId)
          .eq('reporter_id', reporterId)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // Optional: Add method to get report count for a post
  Future<int> getPostReportCount(String postId) async {
    try {
      final response = await supabaseClient
          .from('reports')
          .select('count')
          .eq('post_id', postId)
          .eq('status', 'pending')
          .single();

      return (response['count'] as int?) ?? 0;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // Optional: Add method to get all reports for moderation
  Future<List<Map<String, dynamic>>> getReports({
    String status = 'pending',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await supabaseClient
          .from('reports')
          .select('''
            *,
            posts (
              id,
              caption,
              image_url,
              video_url
            ),
            profiles!reports_reporter_id_fkey (
              id,
              name,
              propic
            )
          ''')
          .eq('status', status)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // Optional: Add method to update report status (for moderators)
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String resolvedBy,
    String? actionTaken,
  }) async {
    try {
      await supabaseClient.from('reports').update({
        'status': status,
        'resolved_at': DateTime.now().toIso8601String(),
        'resolved_by': resolvedBy,
        'action_taken': actionTaken,
      }).eq('id', reportId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      // Check if like exists
      final existingLike = await supabaseClient
          .from(AppConstants.likesTable)
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike == null) {
        // Add like
        await supabaseClient.from(AppConstants.likesTable).insert({
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Remove like
        await supabaseClient
            .from(AppConstants.likesTable)
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
  Future<int> getPostLikesCount(String postId) async {
    try {
      final response = await supabaseClient
          .from(AppConstants.likesTable)
          .select('count')
          .eq('post_id', postId)
          .single();

      return (response['count'] as int?) ?? 0;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> isPostLikedByUser({
    required String postId,
    required String userId,
  }) async {
    try {
      final response = await supabaseClient
          .from(AppConstants.likesTable)
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
