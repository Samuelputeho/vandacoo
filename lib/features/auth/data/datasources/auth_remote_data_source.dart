import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/error/exceptions.dart';
import 'package:vandacoo/core/common/models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Session? get currentUserSession;
  Future<UserModel> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required String accountType,
    required String gender,
    required String age,
  });

  Future<void> updateUserProfile({
    String? userId,
    String? email,
    String? name,
    String? bio,
    File? imagePath, // Path to the local image file
  });

  Future<void> updateHasSeenIntroVideo(String userId);

  Future<void> logout();

  Future<UserModel> logInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserModel?> getCurrentUserData();

  Future<List<UserModel>> getAllUsers();

  Future<bool> checkUserStatus(String userId);

  Future<void> sendPasswordResetToken({
    required String email,
  });

  Future<void> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  static const _timeout = Duration(seconds: 10);

  @override
  Session? get currentUserSession => supabaseClient.auth.currentSession;

  AuthRemoteDataSourceImpl(this.supabaseClient);
  @override
  Future<UserModel> logInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        password: password,
        email: email,
      );
      if (response.user == null) {
        throw ServerException("User is null!");
      }

      // Fetch the user's profile data
      final userData = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      // Check if the user's status is active
      if (userData['status'] != 'active') {
        // Sign out the user since they're not active
        await supabaseClient.auth.signOut();
        throw ServerException("Account is not active. Please contact support.");
      }

      // Combine profile data with auth email
      return UserModel.fromJson(userData).copyWith(
        email: response.user!.email,
      );
    } catch (e) {
      throw ServerException(
        e.toString(),
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required String accountType,
    required String gender,
    required String age,
  }) async {
    try {
      final response = await supabaseClient.auth
          .signUp(password: password, email: email, data: {
        'name': name,
        'account_type': accountType,
        'gender': gender,
        'age': age,
      });

      if (response.user == null) {
        throw ServerException("User is null!");
      }

      // Create initial profile in the profiles table
      await supabaseClient.from('profiles').upsert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'bio': '',
        'propic': '',
        'has_seen_intro_video': false,
        'account_type': accountType,
        'gender': gender,
        'age': age,
        'status': 'active', // Explicitly set status to active
      });

      // Get the created profile
      final userData = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(userData).copyWith(
        email: response.user!.email,
        hasSeenIntroVideo: false,
        age: age,
      );
    } catch (e) {
      throw ServerException(
        e.toString(),
      );
    }
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUserSession != null) {
        final userData = await supabaseClient.from('profiles').select('''
              *,
              followers:follows!follows_follower_id_fkey(
                follower:profiles!follows_follower_id_fkey(*)
              ),
              following:follows!follows_follower_id_fkey(
                following:profiles!follows_following_id_fkey(*)
              )
            ''').eq('id', currentUserSession!.user.id).single().timeout(
              _timeout,
              onTimeout: () => throw ServerException(
                  'Connection timeout. Please check your internet connection.'),
            );

        // Check if the user's status is active
        if (userData['status'] != 'active') {
          // Sign out the user since they're not active
          await supabaseClient.auth.signOut();
          throw ServerException(
              "Account is not active. Please contact support.");
        }

        // Extract followers and following from the nested data
        final List<dynamic> followersData = (userData['followers'] ?? [])
            .map((f) => f['follower'])
            .where((f) => f != null)
            .toList();
        final List<dynamic> followingData = (userData['following'] ?? [])
            .map((f) => f['following'])
            .where((f) => f != null)
            .toList();

        // Create a new map with the processed data and explicitly cast it
        final processedData = <String, dynamic>{
          ...Map<String, dynamic>.from(userData),
          'followers': followersData,
          'following': followingData,
        };

        return UserModel.fromJson(processedData).copyWith(
          email: currentUserSession!.user.email,
        );
      }

      return null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await supabaseClient.from('profiles').select('''
        *,
        followers:follows!follows_following_id_fkey(
          follower:profiles!follows_follower_id_fkey(*)
        ),
        following:follows!follows_follower_id_fkey(
          following:profiles!follows_following_id_fkey(*)
        )
      ''').eq('status', 'active').timeout(
            _timeout,
            onTimeout: () => throw ServerException(
                'Connection timeout. Please check your internet connection.'),
          );

      return (response as List).map((userData) {
        // Extract followers and following from the nested data
        final List<dynamic> followersData = (userData['followers'] ?? [])
            .map((f) => f['follower'])
            .where((f) => f != null)
            .toList();
        final List<dynamic> followingData = (userData['following'] ?? [])
            .map((f) => f['following'])
            .where((f) => f != null)
            .toList();

        // Create a new map with the processed data and explicitly cast it
        final processedData = <String, dynamic>{
          ...Map<String, dynamic>.from(userData),
          'followers': followersData,
          'following': followingData,
        };

        return UserModel.fromJson(processedData);
      }).toList();
    } on TimeoutException {
      throw ServerException(
          'Connection timeout. Please check your internet connection.');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateUserProfile({
    String? userId,
    String? name,
    String? email,
    String? bio,
    File? imagePath,
  }) async {
    try {
      String? publicURL;

      // Only handle image upload if an image is provided
      if (imagePath != null) {
        // 1. Upload image to bucket
        final fileName = "${DateTime.now().millisecondsSinceEpoch}_$userId.jpg";
        final storageResponse = await supabaseClient.storage
            .from('profile-pictures')
            .upload(fileName, imagePath);

        if (storageResponse.isEmpty) {
          throw ServerException("Image upload failed.");
        }

        // 2. Get public URL for the uploaded image
        publicURL = supabaseClient.storage
            .from('profile-pictures')
            .getPublicUrl(fileName);

        if (publicURL.isEmpty) {
          throw ServerException("Failed to retrieve public URL for image.");
        }
      }

      // 3. Update user's profile in the database
      final updateData = {
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (email != null) 'email': email,
        if (publicURL != null) 'propic': publicURL,
      };

      if (updateData.isNotEmpty) {
        final updateResponse = await supabaseClient
            .from('profiles')
            .update(updateData)
            .eq('id', userId!);

        if (updateResponse.error != null) {
          throw ServerException(
              "Failed to update profile: ${updateResponse.error!.message}");
        }
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateHasSeenIntroVideo(String userId) async {
    try {
      await supabaseClient
          .from('profiles')
          .update({'has_seen_intro_video': true}).eq('id', userId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> checkUserStatus(String userId) async {
    try {
      final userData = await supabaseClient
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .single();

      return userData['status'] == 'active';
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetToken({
    required String email,
  }) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: null, // We'll handle the reset in-app
      );
    } catch (e) {
      throw ServerException(
        'Failed to send reset token: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      // First, verify the reset token by attempting to create a session with it
      final response = await supabaseClient.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );

      if (response.user == null) {
        throw ServerException('Invalid or expired reset token');
      }

      // Update the password for the authenticated user
      final updateResponse = await supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (updateResponse.user == null) {
        throw ServerException('Failed to update password');
      }

      // Sign out the user after password reset for security
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw ServerException(
        'Failed to reset password: ${e.toString()}',
      );
    }
  }
}
