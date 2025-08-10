import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import 'package:vandacoo/core/common/models/post_model.dart';
import 'package:vandacoo/core/common/models/user_model.dart';

abstract interface class ProfileRemoteDatasource {
  Future<List<PostModel>> getPostsForUser(String userId);
  Future<UserModel> getUserInformation(String userId);
  Future<void> editUserInfo({
    required String userId,
    String? name,
    String? bio,
    String? email,
    File? propicFile, // Handles image file upload
  });
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final SupabaseClient supabase;

  ProfileRemoteDatasourceImpl({required this.supabase});

  @override
  Future<List<PostModel>> getPostsForUser(String userId) async {
    try {
      final response = await supabase.from('posts').select('''
            *,
            profiles!inner(
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
            )
          ''').eq('user_id', userId).eq('profiles.status', 'active');

      return response.map((post) {
        final profileData = post['profiles'] as Map<String, dynamic>;
        String? proPic = profileData['propic'] as String?;
        if (proPic != null) {
          proPic = proPic.trim().replaceAll(RegExp(r'\s+'), '');
        }

        return PostModel.fromJson(post).copyWith(
          posterName: profileData['name'] as String?,
          posterProPic: proPic,
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
  Future<UserModel> getUserInformation(String userId) async {
    try {
      final userData = await supabase.from('profiles').select('''
        *,
        followers:follows!follows_following_id_fkey(
          follower:profiles!follows_follower_id_fkey(*)
        ),
        following:follows!follows_follower_id_fkey(
          following:profiles!follows_following_id_fkey(*)
        )
      ''').eq('id', userId).eq('status', 'active').single();

      final List<dynamic> followersData = (userData['followers'] ?? [])
          .map((f) => f['follower'])
          .where((f) => f != null)
          .toList();
      final List<dynamic> followingData = (userData['following'] ?? [])
          .map((f) => f['following'])
          .where((f) => f != null)
          .toList();

      final processedData = <String, dynamic>{
        ...Map<String, dynamic>.from(userData),
        'followers': followersData,
        'following': followingData,
      };

      return UserModel.fromJson(processedData);
    } on PostgrestException catch (e) {
      if (e.message.contains('No rows found')) {
        throw ServerException(
            "Account is not active or not found. Please contact support.");
      }
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> editUserInfo({
    required String userId,
    String? name,
    String? bio,
    String? email,
    File? propicFile,
  }) async {
    try {
      String? uploadedProPicUrl;

      if (propicFile != null) {
        final fileName =
            'profile-pictures/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final uploadResponse = await supabase.storage
            .from('profile-pictures')
            .upload(fileName, propicFile);

        if (uploadResponse.toString().contains("error")) {
          throw Exception(
              'Error uploading profile picture, raw response: $uploadResponse');
        }

        uploadedProPicUrl =
            supabase.storage.from('profile-pictures').getPublicUrl(fileName);
      }

      final Map<String, dynamic> updateData = {};
      if (uploadedProPicUrl != null) updateData['propic'] = uploadedProPicUrl;
      if (name != null) updateData['name'] = name;
      if (bio != null) updateData['bio'] = bio;
      if (email != null) updateData['email'] = email;

      if (updateData.isNotEmpty) {
        await supabase.from('profiles').update(updateData).eq('id', userId);
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
