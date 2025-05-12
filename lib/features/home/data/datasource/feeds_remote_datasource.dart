import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart'
    show FileOptions, StorageException, SupabaseClient;

import '../../../../core/constants/app_consts.dart' show AppConstants;
import '../../../../core/error/exceptions.dart' show ServerException;

abstract interface class FeedsRemoteDataSource {
  Future<void> uploadPost({
    required String userId,
    required String postType,
    required String caption,
    required String region,
    required String category,
    required int durationDays,
    File? mediaFile,
    File? thumbnailFile,
    String status = 'active',
  });

  Future<String> uploadImage({
    required File file,
  });

  Future<String> uploadVideo({
    required File file,
  });
}

class FeedsRemoteDataSourceImpl implements FeedsRemoteDataSource {
  final SupabaseClient supabaseClient;

  FeedsRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<String> uploadImage({
    required File file,
  }) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw ServerException('User is not authenticated');
      }

      final String fileName = file.path.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String path = '${timestamp}_$fileName';

      await supabaseClient.storage.from(AppConstants.postImagesBucket).upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final String imageUrl = supabaseClient.storage
          .from(AppConstants.postImagesBucket)
          .getPublicUrl(path);
      return imageUrl;
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> uploadPost({
    required String userId,
    required String postType,
    required String caption,
    required String region,
    required String category,
    required int durationDays,
    File? mediaFile,
    File? thumbnailFile,
    String status = 'active',
  }) async {
    try {
      String? finalImageUrl;
      String? finalVideoUrl;

      // Handle media uploads first
      if (mediaFile != null && mediaFile.existsSync()) {
        final String fileExtension =
            mediaFile.path.split('.').last.toLowerCase();
        final bool isVideo =
            ['mp4', 'mov', 'avi', 'mkv', '3gp', 'wmv'].contains(fileExtension);

        if (isVideo) {
          finalVideoUrl = await uploadVideo(file: mediaFile);
          if (thumbnailFile != null && thumbnailFile.existsSync()) {
            finalImageUrl = await uploadImage(file: thumbnailFile);
          }
        } else {
          finalImageUrl = await uploadImage(file: mediaFile);
        }
      }

      // Prepare post data with simplified date handling
      final Map<String, dynamic> postData = {
        'user_id': userId,
        'post_type': postType,
        'caption': caption,
        'region': region,
        'category': category,
        'image_url': finalImageUrl,
        'video_url': finalVideoUrl,
        'status': status,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'duration_days': durationDays,
        'expires_at': DateTime.now()
            .toUtc()
            .add(Duration(days: durationDays))
            .toIso8601String(),
        'is_expired': false,
      };

      // Insert data with simplified query
      await supabaseClient.from(AppConstants.postTable).insert(postData);
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadVideo({
    required File file,
  }) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw ServerException('User is not authenticated');
      }

      if (!file.existsSync()) {
        throw ServerException('Video file not found');
      }

      final String fileName = file.path.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String path = '${timestamp}_$fileName';

      await supabaseClient.storage.from(AppConstants.postVideosBucket).upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'video/mp4',
            ),
          );

      final String videoUrl = supabaseClient.storage
          .from(AppConstants.postVideosBucket)
          .getPublicUrl(path);

      print('Video uploaded with URL: $videoUrl');
      return videoUrl;
    } on StorageException catch (e) {
      if (e.statusCode == 403) {
        throw ServerException(
            'Permission denied: Please check if you are logged in and have the right permissions');
      }
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
