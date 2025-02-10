import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/core/common/cubits/bookmark/bookmark_cubit.dart';
import 'package:vandacoo/core/common/global_comments/presentation/bloc/global_comments/global_comments_bloc.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/features/auth/presentation/pages/login_page.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/comments_bloc/comment_bloc.dart';
import 'package:vandacoo/core/common/pages/bottom_navigation_bar_screen.dart';
import 'package:vandacoo/features/messages/presentation/bloc/messages_bloc/message_bloc.dart';
import 'package:vandacoo/core/theme/bloc/theme_bloc.dart';
import 'package:vandacoo/core/theme/bloc/theme_state.dart';
import 'package:vandacoo/features/profile/presentation/bloc/bloc/profile_bloc.dart';
import 'core/common/entities/post_entity.dart';
import 'core/common/widgets/loader.dart';
import 'core/utils/show_snackbar.dart';
import 'features/explore_page/presentation/bloc/explore_bookmark_bloc/explore_bookmark_bloc.dart';
import 'features/explore_page/presentation/bloc/post_bloc/post_bloc.dart';
import 'package:vandacoo/features/follow_page/presentation/pages/follow_page.dart';
import 'features/upload_media_page/presentation/bloc/upload/upload_bloc.dart';
import 'init_dependencies.dart';
import 'package:vandacoo/features/messages/presentation/pages/chat_page.dart';
import 'package:vandacoo/features/messages/presentation/pages/new_message_page.dart';
import 'package:vandacoo/features/bookmark_page/presentation/page/bookmarkpage.dart';
import 'package:vandacoo/features/bookmark_page/presentation/bloc/bloc/settings_bookmark_bloc.dart';
import 'package:vandacoo/features/follow_page/presentation/pages/follow_page_post_listview.dart';
import 'package:vandacoo/features/profile/presentation/pages/profile_post_listview.dart';

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
        create: (_) => serviceLocator<AuthBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<PostBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<CommentBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<GlobalCommentsBloc>(),
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
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthIsUserLoggedIn());
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
                showSnackBar(context, state.message);
              }
              if (state is AuthSuccess) {
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

                //                context
                //                    .read<ProfileBloc>()
                //                    .add(GetUserPostsEvent(userId: state.user.id));
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
              );
            },
          },
        );
      },
    );
  }
}
