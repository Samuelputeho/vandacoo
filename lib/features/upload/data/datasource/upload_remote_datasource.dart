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
    File? imageFile,
    String? videoUrl,
    String status = 'active',
  });

  Future<String> uploadImage({
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
    File? imageFile,
    String? videoUrl,
    String status = 'active',
  }) async {
    try {
      String? finalImageUrl;

      if (imageFile != null) {
        finalImageUrl = await uploadImage(
          file: imageFile,
        );
      }

      final postData = {
        'user_id': userId,
        'post_type': postType,
        'caption': caption,
        'region': region,
        'category': category,
        'image_url': finalImageUrl,
        'video_url': videoUrl,
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
}
