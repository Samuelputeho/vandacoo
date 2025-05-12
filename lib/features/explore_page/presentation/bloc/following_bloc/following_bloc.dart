import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/features/explore_page/domain/usecases/get_all_posts_usecase.dart';
import 'package:vandacoo/features/explore_page/domain/usecases/get_current_user_information_usecase.dart';

part 'following_event.dart';
part 'following_state.dart';

class FollowingBloc extends Bloc<FollowingEvent, FollowingState> {
  final GetAllPostsUsecase getAllPostsUsecase;
  final GetCurrentUserInformationUsecase getCurrentUserInformationUsecase;

  // Cache for posts and current user
  static List<PostEntity> _currentPosts = [];
  static UserEntity? _currentUser;

  List<PostEntity> get currentPosts => _currentPosts;
  UserEntity? get currentUser => _currentUser;

  FollowingBloc({
    required this.getAllPostsUsecase,
    required this.getCurrentUserInformationUsecase,
  }) : super(FollowingInitial()) {
    on<GetFollowingPostsEvent>(_handleGetFollowingPosts);
  }

  Future<void> _handleGetFollowingPosts(
    GetFollowingPostsEvent event,
    Emitter<FollowingState> emit,
  ) async {
    try {
      // If we have cached data, emit loading with cache
      if (_currentPosts.isNotEmpty && _currentUser != null) {
        emit(FollowingLoadingCache(
          posts: _currentPosts,
          currentUser: _currentUser!,
        ));
      } else {
        emit(FollowingLoading());
      }

      // Get current user information first
      final userResult = await getCurrentUserInformationUsecase(
        GetCurrentUserInformationUsecaseParams(userId: event.userId),
      );

      await userResult.fold(
        (failure) async => emit(FollowingError(message: failure.message)),
        (user) async {
          _currentUser = user;

          // Get all posts
          final postsResult = await getAllPostsUsecase(event.userId);

          await postsResult.fold(
            (failure) async => emit(FollowingError(message: failure.message)),
            (allPosts) async {
              // Filter posts to only show posts (not stories) from followed users
              final followingPosts = allPosts
                  .where((post) =>
                      // Check if the post's user is in the current user's following list
                      user.following.any(
                          (followedUser) => followedUser.id == post.userId) &&
                      // Only include posts, not stories, and exclude Feeds category
                      post.postType == 'Post' &&
                      post.category != 'Feeds')
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              // Update cache
              _currentPosts = followingPosts;

              emit(FollowingPostsLoaded(
                posts: followingPosts,
                currentUser: user,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(FollowingError(message: e.toString()));
    }
  }
}
