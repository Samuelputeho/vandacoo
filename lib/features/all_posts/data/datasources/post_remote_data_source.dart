import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/common/models/post_model.dart';
import 'package:vandacoo/core/constants/app_consts.dart';
import 'package:vandacoo/core/error/exceptions.dart';

import '../../../../core/common/models/story_model.dart';

abstract interface class PostRemoteDataSource {
  Future<PostModel> uploadPost(PostModel post);
  Future<String> uploadImage({
    required File image,
    required PostModel post,
  });
  Future<List<PostModel>> getAllPosts();
  Future<void> markStoryAsViewed(String storyId, String viewerId);
  Future<List<StoryModel>> getViewedStories(String viewerId);
  Future<void> deletePost(String postId);
  // Update post caption
  Future<void> updatePostCaption({
    required String postId,
    required String caption,
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
  Future<List<PostModel>> getAllPosts() async {
    try {
      final posts = await supabaseClient.from(AppConstants.postTable).select('''
            *,
            profiles!posts_user_id_fkey (
              name,
              propic
            )
          ''').eq('status', 'active').order('updated_at', ascending: false);

      return posts.map((post) {
        final profileData = post['profiles'] as Map<String, dynamic>;
        return PostModel.fromJson(post).copyWith(
          posterName: profileData['name'] as String?,
          posterProPic: profileData['propic'] as String?,
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
}
