import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/features/profile/domain/usecases/get_poster_for_user.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetPosterForUserUsecase getPosterForUserUsecase;

  ProfileBloc({required this.getPosterForUserUsecase})
      : super(ProfileInitial()) {
    on<GetUserPostsEvent>(_handleGetUserPosts);
  }

  Future<void> _handleGetUserPosts(
    GetUserPostsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final result = await getPosterForUserUsecase(event.userId);

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (posts) {
        // Filter out stories, only keep posts
        final filteredPosts =
            posts.where((post) => post.postType == 'Post').toList();
        emit(ProfilePostsLoaded(posts: filteredPosts));
      },
    );
  }
}
