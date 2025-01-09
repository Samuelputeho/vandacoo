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
    File? mediaFile,
    String status = 'active',
  }) async {
    try {
      String? finalImageUrl;
      String? finalVideoUrl;

      if (mediaFile != null) {
        if (!mediaFile.existsSync()) {
          throw ServerException('Media file not found');
        }

        final String fileExtension =
            mediaFile.path.split('.').last.toLowerCase();
        final bool isVideo =
            ['mp4', 'mov', 'avi', 'mkv', '3gp', 'wmv'].contains(fileExtension);

        if (isVideo) {
          finalVideoUrl = await uploadVideo(file: mediaFile);
        } else {
          finalImageUrl = await uploadImage(file: mediaFile);
        }
      }

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

      await supabaseClient
          .from(AppConstants.postTable)
          .insert(postData)
          .select();
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } on PostgrestException catch (e) {
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
            ),
          );

      final String videoUrl = supabaseClient.storage
          .from(AppConstants.postVideosBucket)
          .getPublicUrl(path);
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
