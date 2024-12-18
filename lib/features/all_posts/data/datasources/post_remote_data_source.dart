import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/common/models/post_model.dart';
import 'package:vandacoo/core/constants/app_consts.dart';
import 'package:vandacoo/core/error/exceptions.dart';

abstract interface class PostRemoteDataSource {
  Future<PostModel> uploadPost(PostModel post);
  Future<String> uploadImage({
    required File image,
    required PostModel post,
  });
  Future<List<PostModel>>getAllPosts();
  
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final SupabaseClient supabaseClient;

  PostRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<PostModel> uploadPost(PostModel post) async {
    try {
      final postData = await supabaseClient
          .from(AppConstants.postCollection)
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
      await supabaseClient.storage.from('post_Images').upload(post.id, image);

      return supabaseClient.storage.from('post_Images').getPublicUrl(post.id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<List<PostModel>> getAllPosts() async {
   try {
     final posts = await supabaseClient
         .from('posts')
         .select('''
           *,
           profiles (
             name,
             propic
           )
         ''')
         .order('updatedAt', ascending: false);
         print('Posts response: $posts'); 

     return posts.map((post) => PostModel.fromJson(post).copyWith(
       posterName: post['profiles']['name'],
       posterProPic: post['profiles']['proPic'],
     )).toList();
   } on PostgrestException catch (e) {
    throw ServerException (e.message);
   
   } catch (e) {
     throw ServerException(e.toString());
   }
  }

  
}
