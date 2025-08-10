import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/features/auth/presentation/pages/login_page.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/comments_bloc/comment_bloc.dart';
import 'package:vandacoo/core/common/pages/bottom_navigation_bar_screen.dart';
import 'package:vandacoo/features/messages/presentation/bloc/messages_bloc/message_bloc.dart';
import 'package:vandacoo/core/theme/bloc/theme_bloc.dart';
import 'package:vandacoo/core/theme/bloc/theme_state.dart';
import 'package:vandacoo/features/profile/presentation/bloc/edit_user_info_bloc/edit_user_info_bloc.dart';
import 'package:vandacoo/features/profile/presentation/bloc/get_user_info_bloc/profile_bloc.dart';
import 'package:vandacoo/features/profile/presentation/bloc/profile_post_bloc/profile_posts_bloc.dart';
import 'core/common/widgets/loader.dart';
import 'core/common/widgets/error_utils.dart';
import 'core/utils/show_snackbar.dart';
import 'core/utils/shared_preferences_with_cache.dart';
import 'features/explore_page/presentation/bloc/explore_bookmark_bloc/explore_bookmark_bloc.dart';
import 'features/explore_page/presentation/bloc/following_bloc/following_bloc.dart';
import 'features/explore_page/presentation/bloc/post_bloc/post_bloc.dart';
import 'package:vandacoo/features/follow_page/presentation/pages/follow_page.dart';
import 'features/explore_page/presentation/bloc/send_message_comment_bloc/send_message_comment_bloc.dart';
import 'features/follow_page/presentation/bloc/follow_count_bloc/follow_count_bloc.dart';
import 'features/home/presentation/bloc/feeds_bloc/feeds_bloc.dart'
    show FeedsBloc;
import 'features/payment_page/presentation/pages/payment_page.dart';
import 'features/upload_media_page/presentation/bloc/upload/upload_bloc.dart';
import 'init_dependencies.dart';
import 'package:vandacoo/features/messages/presentation/pages/chat_page.dart';
import 'package:vandacoo/features/messages/presentation/pages/new_message_page.dart';
import 'package:vandacoo/features/bookmark_page/presentation/page/bookmarkpage.dart';
import 'package:vandacoo/features/bookmark_page/presentation/bloc/bloc/settings_bookmark_bloc.dart';
import 'package:vandacoo/features/follow_page/presentation/pages/follow_page_post_listview.dart';
import 'package:vandacoo/features/profile/presentation/pages/profile_post_listview.dart';
import 'package:vandacoo/features/home/presentation/pages/feed_screen.dart';
import 'package:vandacoo/features/profile/presentation/pages/profile_screen.dart';
import 'package:vandacoo/features/follow_page/presentation/bloc/follow_bloc/follow_page_bloc.dart';
import 'package:vandacoo/features/home/presentation/pages/upload_feeds.dart';
import 'package:vandacoo/core/common/cubits/stories_viewed/stories_viewed_cubit.dart';
import 'features/settings/presentation/bloc/notification_settings/notification_settings_bloc.dart';
import 'features/settings/presentation/bloc/notification_settings/notification_settings_event.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // Initialize SharedPreferences first

  await initdependencies();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => serviceLocator<AppUserCubit>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<GlobalCommentsBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<AuthBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<PostBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<CommentBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<MessageBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<ThemeBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<UploadBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<ExploreBookmarkBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<BookmarkCubit>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<SettingsBookmarkBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<ProfileBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<ProfilePostsBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<EditUserInfoBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<FollowPageBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<FollowCountBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<FollowingBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<SendMessageCommentBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<FeedsBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<StoriesViewedCubit>(),
      ),
      BlocProvider(
        create: (_) => NotificationSettingsBloc(
          SharedPreferencesWithCache.fromPrefs(serviceLocator()),
        )..add(const NotificationSettingsLoadRequested()),
      ),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AuthBloc>().add(AuthIsUserLoggedIn());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentUserId != null) {
      // App resumed from background, check user status
      context
          .read<AuthBloc>()
          .add(AuthCheckUserStatus(userId: _currentUserId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Vand',
          theme: state.themeData,
          builder: (context, child) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
            return child!;
          },
          home: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailure) {
                // Check if this is a network error
                final isNetworkError = ErrorUtils.isNetworkError(state.message);
                if (isNetworkError) {
                  // For network errors, check if user was previously logged in
                  final appUserState = context.read<AppUserCubit>().state;
                  if (appUserState is AppUserLoggedIn) {
                    // User was previously authenticated, show network error but keep them logged in
                    showSnackBar(context, state.message);
                    // Don't clear current user ID for network errors
                    return;
                  }
                }
                // For non-network errors or when no previous user state, clear user ID
                showSnackBar(context, state.message);
                _currentUserId = null;
              }
              if (state is AuthSuccess) {
                // Store current user ID for lifecycle checks
                _currentUserId = state.user.id;

                context.read<CommentBloc>().add(GetAllCommentsEvent());
                context
                    .read<GlobalCommentsBloc>()
                    .add(GetAllGlobalCommentsEvent());
                context
                    .read<GlobalCommentsBloc>()
                    .add(GetAllGlobalPostsEvent(userId: state.user.id));

                context
                    .read<PostBloc>()
                    .add(GetAllPostsEvent(userId: state.user.id));

                context
                    .read<ProfilePostsBloc>()
                    .add(GetUserPostsEvent(userId: state.user.id));

                context
                    .read<ProfileBloc>()
                    .add(GetUserInfoEvent(userId: state.user.id));
                context
                    .read<ProfilePostsBloc>()
                    .add(GetUserPostsEvent(userId: state.user.id));

                context
                    .read<EditUserInfoBloc>()
                    .add(UpdateUserInfoEvent(userId: state.user.id));

                // Check for unread messages when app opens
                context.read<MessageBloc>().add(
                      FetchAllMessagesEvent(userId: state.user.id),
                    );
              }
            },
            builder: (context, authState) {
              if (authState is AuthLoading && authState is! AuthUsersLoaded) {
                return const Scaffold(
                  body: Loader(),
                );
              }

              if (authState is AuthSuccess) {
                return BottomNavigationBarScreen(user: authState.user);
              } else if (authState is AuthFailure) {
                // Check if this is a network error
                final isNetworkError =
                    ErrorUtils.isNetworkError(authState.message);
                if (isNetworkError) {
                  // For network errors, check if user was previously logged in
                  final appUserState = context.read<AppUserCubit>().state;
                  if (appUserState is AppUserLoggedIn) {
                    // User was previously authenticated, keep them logged in despite network error
                    return BottomNavigationBarScreen(user: appUserState.user);
                  }
                }
                // For non-network errors or when no previous user state, show login screen
                return const LoginScreen();
              }

              return const LoginScreen();
            },
          ),
          routes: {
            '/new-message': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return NewMessagePage(
                  currentUserId: args['currentUserId'] as String);
            },
            '/upload-feeds': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
              return UploadFeedsPage(
                durationDays: args?['durationDays'],
              );
            },
            '/chat': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return ChatPage(
                currentUserId: args['currentUserId'] as String,
                otherUserId: args['otherUserId'] as String,
                otherUserName: args['otherUserName'] as String,
                otherUserProPic: args['otherUserProPic'] as String,
              );
            },
            '/bookmarks': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return BookMarkPage(
                userId: args['userId'] as String,
              );
            },
            '/follow': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return FollowPage(
                userId: args['userId'] as String,
                userName: args['userName'] as String,
                userPost: args['userPost'] as PostEntity,
                userEntirePosts: args['userEntirePosts'] as List<PostEntity>,
                currentUser: args['currentUser'] as UserEntity,
              );
            },
            '/follow-posts': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return FollowPageListView(
                userId: args['userId'] as String,
                userPosts: args['userPosts'] as List<PostEntity>,
                selectedPost: args['selectedPost'] as PostEntity,
              );
            },
            '/profile-posts': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return ProfilePostListView(
                userId: args['userId'] as String,
                userPosts: args['userPosts'] as List<PostEntity>,
                selectedPost: args['selectedPost'] as PostEntity,
                screenType: args['screenType'] as String,
              );
            },
            '/feed': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return FeedScreen(
                user: args['user'] as UserEntity,
              );
            },
            '/profile': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return ProfileScreen(
                user: args['user'] as UserEntity,
              );
            },
            '/payment': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return PaymentPage(
                user: args['user'] as UserEntity,
              );
            },
          },
          navigatorObservers: [routeObserver],
        );
      },
    );
  }
}
