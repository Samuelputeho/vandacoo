import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/app_consts.dart';
import '../../../../error/exceptions.dart';
import '../../../models/comment_model.dart';
import '../../../models/post_model.dart';
import '../../../models/user_model.dart';

abstract interface class GlobalCommentsRemoteDatasource {
  Future<List<PostModel>> getAllPosts(String userId);

  Future<void> toggleBookmark(String postId);

//delete comment
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  });

  // Delete post
  Future<void> deletePost(String postId);

// read comment
  Future<List<CommentModel>> getComments(String posterId);
// add comment
  Future<CommentModel> addComment(
      String posterId, String userId, String comment);

  // get all comments
  // read all comments
  Future<List<CommentModel>> getAllComments();

  // update post caption
  Future<void> updatePostCaption({
    required String postId,
    required String caption,
  });

  // Report related methods
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

  Future<void> markStoryAsViewed({
    required String storyId,
    required String userId,
  });

  Future<List<String>> getViewedStories(String userId);
}

class GlobalCommentsRemoteDatasourceImpl
    implements GlobalCommentsRemoteDatasource {
  final SupabaseClient supabaseClient;

  GlobalCommentsRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<PostModel>> getAllPosts(String userId) async {
    try {
      final posts = await supabaseClient
          .from(AppConstants.postTable)
          .select('''
            *,
            profiles!inner (
              id,
              email,
              name,
              bio,
              propic,
              account_type,
              gender,
              age,
              has_seen_intro_video,
              status
            ),
            bookmarks!left (
              user_id
            ),
            likes!left (
              user_id
            ),
            likes_count:likes(count)
          ''')
          .eq('status', 'active')
          .eq('profiles.status', 'active')
          .eq('is_expired', false)
          .or('expires_at.gt.now,expires_at.is.null')
          .order('created_at', ascending: false);

      return posts.map((post) {
        final profileData = post['profiles'] as Map<String, dynamic>;
        String? proPic = profileData['propic'] as String?;
        if (proPic != null) {
          proPic = proPic.trim().replaceAll(RegExp(r'\s+'), '');
        }

        final bookmarks = post['bookmarks'] as List<dynamic>;
        final isBookmarked =
            bookmarks.any((bookmark) => bookmark['user_id'] == userId);

        final likes = post['likes'] as List<dynamic>;
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
          likesCount = 0;
        }

        return PostModel.fromJson(post).copyWith(
          posterName: profileData['name'] as String?,
          posterProPic: proPic,
          isBookmarked: isBookmarked,
          isLiked: isPostLikedByUser,
          likesCount: likesCount,
          isPostLikedByUser: isPostLikedByUser,
          user: UserModel.fromJson(profileData),
        );
      }).toList();
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
      // First check if the user is active
      final userStatus = await supabaseClient
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .single();

      if (userStatus['status'] != 'active') {
        throw ServerException("Only active users can add comments.");
      }

      final timestamp = DateTime.now().toIso8601String();

      final response =
          await supabaseClient.from(AppConstants.commentsTable).insert({
        'posterId': posterId,
        'userId': userId,
        'comment': comment,
        'createdAt': timestamp,
      }).select('''
        *,
        profiles!inner (
          id,
          name,
          propic
        )
      ''').single();

      return CommentModel.fromJson(response).copyWith(
        userName: response['profiles']['name'],
        userProPic: response['profiles']['propic'],
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CommentModel>> getAllComments() async {
    try {
      final comments = await supabaseClient
          .from(AppConstants.commentsTable)
          .select('''
            *,
            profiles!inner (
              id,
              name,
              propic,
              status
            )
          ''')
          .eq('profiles.status', 'active')
          .order('createdAt', ascending: true);

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
      final comments = await supabaseClient
          .from(AppConstants.commentsTable)
          .select('''
            *,
            profiles!inner (
              id,
              name,
              propic,
              status
            )
          ''')
          .eq('posterId', posterId)
          .eq('profiles.status', 'active')
          .order('createdAt', ascending: true);

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
  Future<void> reportPost({
    required String postId,
    required String reporterId,
    required String reason,
    String? description,
  }) async {
    try {
      // Check if reporter is active
      final userStatus = await supabaseClient
          .from('profiles')
          .select('status')
          .eq('id', reporterId)
          .single();

      if (userStatus['status'] != 'active') {
        throw ServerException("Only active users can report posts.");
      }

      // Check if user has already reported this post
      final hasReported = await hasUserReportedPost(
        postId: postId,
        reporterId: reporterId,
      );

      if (hasReported) {
        throw ServerException('You have already reported this post');
      }

      // Add report
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

  @override
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      // Check if user is active
      final userStatus = await supabaseClient
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .single();

      if (userStatus['status'] != 'active') {
        throw ServerException("Only active users can like posts.");
      }

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
            .match({'post_id': postId, 'user_id': userId});
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

  @override
  Future<void> toggleBookmark(String postId) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;

      if (userId == null) {
        throw ServerException('User not authenticated');
      }

      // Check if user is active
      final userStatus = await supabaseClient
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .single();

      if (userStatus['status'] != 'active') {
        throw ServerException("Only active users can bookmark posts.");
      }

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
            .match({'post_id': postId, 'user_id': userId});
      }
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
  Future<void> markStoryAsViewed({
    required String storyId,
    required String userId,
  }) async {
    try {
      // Use upsert to handle unique constraint properly
      await supabaseClient.from(AppConstants.storyViewsTable).upsert(
        {
          'story_id': storyId,
          'viewer_id': userId,
          'viewed_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'story_id, viewer_id',
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<String>> getViewedStories(String userId) async {
    try {
      final response = await supabaseClient
          .from(AppConstants.storyViewsTable)
          .select('story_id')
          .eq('viewer_id', userId);

      final viewedStoryIds =
          response.map<String>((row) => row['story_id'] as String).toList();

      return viewedStoryIds;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
