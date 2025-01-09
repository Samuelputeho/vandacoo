import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/app_consts.dart';

abstract interface class UploadRemoteDataSource {
  Future<void> uploadPost({
    required String userId,
    required String postType,
    required String caption,
    required String region,
    required String category,
    File? mediaFile,
    String status = 'active',
  });

  Future<String> uploadImage({
    required File file,
  });

  Future<String> uploadVideo({
    required File file,
  });
}

class UploadRemoteDataSourceImpl implements UploadRemoteDataSource {
  final SupabaseClient supabaseClient;

  UploadRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<String> uploadImage({
    required File file,
  }) async {
    try {
      final String fileName = file.path.split('/').last;
      final String path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await supabaseClient.storage.from(AppConstants.postImagesBucket).upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
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
    File? mediaFile,
    String status = 'active',
  }) async {
    try {
      String? finalImageUrl;
      String? finalVideoUrl;

      if (mediaFile != null) {
        print('Processing media file: ${mediaFile.path}');
        if (!mediaFile.existsSync()) {
          print('Media file does not exist at path: ${mediaFile.path}');
          throw ServerException('Media file not found');
        }

        final String fileExtension =
            mediaFile.path.split('.').last.toLowerCase();
        final bool isVideo =
            ['mp4', 'mov', 'avi', 'mkv', '3gp', 'wmv'].contains(fileExtension);
        print(
            'File type: ${isVideo ? "video" : "image"} (extension: $fileExtension)');

        if (isVideo) {
          print('Uploading video file...');
          finalVideoUrl = await uploadVideo(file: mediaFile);
        } else {
          print('Uploading image file...');
          finalImageUrl = await uploadImage(file: mediaFile);
        }
      }

      print('Preparing post data...');
      final postData = {
        'user_id': userId,
        'post_type': postType,
        'caption': caption,
        'region': region,
        'category': category,
        'image_url': finalImageUrl,
        'video_url': finalVideoUrl,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': null,
      };

      print('Inserting post data into database...');
      await supabaseClient
          .from(AppConstants.postTable)
          .insert(postData)
          .select();
      print('Post data inserted successfully');
    } on StorageException catch (e) {
      print('StorageException: ${e.message}');
      print('StorageException details: ${e.statusCode}, ${e.error}');
      throw ServerException(e.message);
    } on PostgrestException catch (e) {
      print('PostgrestException: ${e.message}');
      print('PostgrestException details: ${e.details}, ${e.hint}');
      throw ServerException(e.message);
    } catch (e, stackTrace) {
      print('Unknown Exception: $e');
      print('Stack trace: $stackTrace');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadVideo({
    required File file,
  }) async {
    try {
      // Check if user is authenticated
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw ServerException('User is not authenticated');
      }

      if (!file.existsSync()) {
        print('Video file does not exist at path: ${file.path}');
        throw ServerException('Video file not found');
      }

      final fileSize = await file.length();
      print('Uploading video file: ${file.path}');
      print('File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Create a more organized storage path with user ID
      final String fileName = file.path.split('/').last;
      final String userId = session.user.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String path = 'user_$userId/${timestamp}_$fileName';
      print('Storage path: $path');

      try {
        await supabaseClient.storage.from(AppConstants.postVideosBucket).upload(
              path,
              file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true, // Changed to true to allow overwrites
              ),
            );

        final String videoUrl = supabaseClient.storage
            .from(AppConstants.postVideosBucket)
            .getPublicUrl(path);
        print('Video uploaded successfully. URL: $videoUrl');
        return videoUrl;
      } on StorageException catch (e) {
        if (e.statusCode == 403) {
          print('Permission denied. Checking bucket policies...');
          // You might want to add specific error handling for different status codes
          throw ServerException(
              'Permission denied: Please ensure you have the right permissions to upload videos');
        }
        rethrow;
      }
    } on StorageException catch (e) {
      print('StorageException during video upload: ${e.message}');
      print('StorageException details: ${e.statusCode}, ${e.error}');
      throw ServerException(e.message);
    } catch (e, stackTrace) {
      print('Unexpected error during video upload: $e');
      print('Stack trace: $stackTrace');
      throw ServerException(e.toString());
    }
  }
}
