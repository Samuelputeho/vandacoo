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

  // Add deduplication tracking
  String? _lastProcessedUserId;
  DateTime? _lastProcessedTime;
  static const int _deduplicationWindowMs = 1000; // 1 second window

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
    print(
        '🔄 FollowingBloc: Processing GetFollowingPostsEvent for user: ${event.userId}');

    // Check if this is a duplicate event within the deduplication window
    final now = DateTime.now();
    if (_lastProcessedUserId == event.userId &&
        _lastProcessedTime != null &&
        now.difference(_lastProcessedTime!).inMilliseconds <
            _deduplicationWindowMs) {
      print(
          '⚠️ FollowingBloc: Duplicate event detected, ignoring. Last processed: ${_lastProcessedTime}, Now: $now');
      return; // Ignore duplicate event
    }

    // Update deduplication tracking
    _lastProcessedUserId = event.userId;
    _lastProcessedTime = now;

    try {
      // Always emit loading state first
      print('⏳ FollowingBloc: Emitting FollowingLoading');
      emit(FollowingLoading());

      // Get current user information first
      final userResult = await getCurrentUserInformationUsecase(
        GetCurrentUserInformationUsecaseParams(userId: event.userId),
      );

      await userResult.fold(
        (failure) async {
          print('❌ FollowingBloc: User fetch failed: ${failure.message}');
          emit(FollowingError(message: failure.message));
        },
        (user) async {
          // Get all posts
          final postsResult = await getAllPostsUsecase(event.userId);

          await postsResult.fold(
            (failure) async {
              print('❌ FollowingBloc: Posts fetch failed: ${failure.message}');
              emit(FollowingError(message: failure.message));
            },
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

              print(
                  '✅ FollowingBloc: Emitting FollowingPostsLoaded with ${followingPosts.length} posts');

              emit(FollowingPostsLoaded(
                posts: followingPosts,
                currentUser: user,
              ));
            },
          );
        },
      );
    } catch (e) {
      print('❌ FollowingBloc: Exception occurred: $e');
      emit(FollowingError(message: e.toString()));
    }
  }
}
