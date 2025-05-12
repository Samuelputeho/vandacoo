import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/features/profile/domain/usecases/get_poster_for_user.dart';

part 'profile_posts_event.dart';
part 'profile_posts_state.dart';

class ProfilePostsBloc extends Bloc<ProfilePostsEvent, ProfilePostsState> {
  final GetPosterForUserUsecase getPosterForUserUsecase;

  // Cache for posts
  static List<PostEntity> _currentPosts = [];
  List<PostEntity> get currentPosts => _currentPosts;

  ProfilePostsBloc({
    required this.getPosterForUserUsecase,
  }) : super(ProfilePostsInitial()) {
    on<GetUserPostsEvent>(_handleGetUserPosts);
  }

  Future<void> _handleGetUserPosts(
    GetUserPostsEvent event,
    Emitter<ProfilePostsState> emit,
  ) async {
    // If we have cached posts, emit loading with cache
    if (_currentPosts.isNotEmpty) {
      emit(ProfilePostsLoadingCache(posts: _currentPosts));
    } else {
      emit(ProfilePostsLoading());
    }

    final result = await getPosterForUserUsecase(event.userId);

    result.fold(
      (failure) {
        emit(ProfilePostsError(message: failure.message));
      },
      (posts) {
        // Filter out stories and Feeds posts
        final filteredPosts = posts
            .where(
                (post) => post.postType == 'Post' && post.category != 'Feeds')
            .toList();
        // Update cache
        _currentPosts = filteredPosts;
        emit(ProfilePostsLoaded(posts: filteredPosts));
      },
    );
  }
}
