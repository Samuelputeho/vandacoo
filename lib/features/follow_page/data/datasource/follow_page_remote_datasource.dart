import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/error/exceptions.dart';
import 'package:vandacoo/core/constants/app_consts.dart';

import '../models/follow_model.dart';

abstract interface class FollowPageRemoteDatasource {
  //method to get the number of posts, followers and following of a user
  Future<FollowModel> getUserCounts(String userId);

  /// Follow a user
  Future<void> followUser(String followerId, String followingId);

  /// Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId);

  /// Get followers of a user
  Future<List<Map<String, dynamic>>> getFollowers(String userId,
      {int limit = 20, int offset = 0});

  /// Get users that a user is following
  Future<List<Map<String, dynamic>>> getFollowing(String userId,
      {int limit = 20, int offset = 0});

  /// Check if a user is following another user
  Future<bool> isFollowing(String followerId, String followingId);

  /// Get follower count for a user
  Future<int> getFollowerCount(String userId);

  /// Get following count for a user
  Future<int> getFollowingCount(String userId);
}

class FollowPageRemoteDataSourceImpl implements FollowPageRemoteDatasource {
  final SupabaseClient _supabaseClient;

  FollowPageRemoteDataSourceImpl(this._supabaseClient);

  @override
  Future<void> followUser(String followerId, String followingId) async {
    try {
      await _supabaseClient.from(AppConstants.followsTable).insert({
        'follower_id': followerId,
        'following_id': followingId,
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to follow user');
    }
  }

  @override
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      await _supabaseClient
          .from(AppConstants.followsTable)
          .delete()
          .match({'follower_id': followerId, 'following_id': followingId});
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to unfollow user');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFollowers(String userId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.followsTable)
          .select('follower_id, profiles!follows_follower_id_fkey(*)')
          .eq('following_id', userId)
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get followers');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFollowing(String userId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.followsTable)
          .select('following_id, profiles!follows_following_id_fkey(*)')
          .eq('follower_id', userId)
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get following users');
    }
  }

  @override
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.followsTable)
          .select()
          .match({
        'follower_id': followerId,
        'following_id': followingId
      }).single();
      return response.isNotEmpty;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No rows returned, means not following
        return false;
      }
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to check follow status');
    }
  }

  @override
  Future<int> getFollowerCount(String userId) async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.followsTable)
          .select()
          .eq('following_id', userId);
      return response.length;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get follower count');
    }
  }

  @override
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.followsTable)
          .select()
          .eq('follower_id', userId);
      return response.length;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get following count');
    }
  }

  @override
  Future<FollowModel> getUserCounts(String userId) async {
    try {
      // Get follower count
      final followerCount = await getFollowerCount(userId);

      // Get following count
      final followingCount = await getFollowingCount(userId);

      // Get posts count
      final postsResponse = await _supabaseClient
          .from(AppConstants.postTable)
          .select()
          .eq('user_id', userId);
      final postsCount = postsResponse.length;

      // Try to get the follow record if it exists
      Map<String, dynamic>? followResponse;
      try {
        final response = await _supabaseClient
            .from(AppConstants.followsTable)
            .select()
            .eq('follower_id', userId)
            .limit(1)
            .maybeSingle();
        followResponse = response;
      } catch (e) {
        // Ignore error if no record found
        followResponse = null;
      }

      return FollowModel(
        id: followResponse?['id'] ?? '',
        followerId: userId,
        followingId: followResponse?['following_id'] ?? '',
        createdAt: followResponse?['created_at'] != null
            ? DateTime.parse(followResponse!['created_at'])
            : DateTime.now(),
        numberOfPosts: postsCount,
        numberOfFollowers: followerCount,
        numberOfFollowing: followingCount,
      );
    } on PostgrestException catch (e) {
      print('error in getUserCounts: $e');
      throw ServerException(e.message);
    } catch (e) {
      print('error in getUserCounts: $e');
      throw ServerException('Failed to get user counts');
    }
  }
}
