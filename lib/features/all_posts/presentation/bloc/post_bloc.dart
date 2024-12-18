import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/all_posts/domain/usecases/get_all_posts_usecase.dart';
import 'package:vandacoo/features/all_posts/domain/usecases/upload_post_usecase.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final UploadPost _uploadPost;
  final GetAllPostsUsecase _getAllPostsUsecase;
  PostBloc({required UploadPost uploadPost,
  required GetAllPostsUsecase getAllPostsUsecase,
  }) : _uploadPost =uploadPost,_getAllPostsUsecase = getAllPostsUsecase, super(PostInitial()) {
    on<PostEvent>((event, emit) => emit(PostLoading()));
    on<PostUploadEvent>(_onPostUpload);
    on<GetAllPostsEvent>(_onGetAllPosts);
  }

  void _onPostUpload(PostUploadEvent event, Emitter<PostState> emit) async {
    final res = await _uploadPost(
      UploadPostParams(
        posterId: event.posterId!,
        caption: event.caption!,
        image: event.image!,
        category: event.category!,
        region: event.region!,
      ),
    );

    res.fold(
      (l) => emit(PostFailure(l.message)),
      (r) => emit(
        PostSuccess(),
      ),
    );
  }

  void _onGetAllPosts(GetAllPostsEvent event, Emitter<PostState> emit,) async{
final res = await _getAllPostsUsecase(NoParams());
res.fold((l)=> emit (PostFailure(l.message)), (r)=> emit(PostDisplaySuccess(r)));
  }
}
