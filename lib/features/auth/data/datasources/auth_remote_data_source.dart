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
        final userData = await supabaseClient
            .from('profiles')
            .select()
            .eq('id', currentUserSession!.user.id);
        return UserModel.fromJson(userData.first).copyWith(
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
      final response = await supabaseClient.from('profiles').select().timeout(
            _timeout,
            onTimeout: () => throw ServerException(
                'Connection timeout. Please check your internet connection.'),
          );

      return (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
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
}
