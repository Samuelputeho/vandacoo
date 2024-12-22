import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/features/auth/presentation/pages/login_page.dart';
import 'package:vandacoo/features/comments/domain/bloc/bloc/comment_bloc.dart';
import 'package:vandacoo/init_dependencies.dart';
import 'package:vandacoo/screens/bottom_navigation_bar_screen.dart';
import 'package:vandacoo/screens/messages/presentation/bloc/message_bloc.dart';
import 'package:vandacoo/core/theme/bloc/theme_bloc.dart';
import 'package:vandacoo/core/theme/bloc/theme_state.dart';
import 'features/all_posts/presentation/bloc/post_bloc.dart';
import 'package:vandacoo/features/likes/presentation/bloc/like_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initdependencies();

  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
    ],
  );
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
        create: (_) => serviceLocator<MessageBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<LikeBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<ThemeBloc>(),
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
            // Lock screen orientation to portrait
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
            return child!;
          },
          home: BlocSelector<AppUserCubit, AppUserState, bool>(
            selector: (state) {
              return state is AppUserLoggedIn;
            },
            builder: (context, isLoggedIn) {
              if (isLoggedIn) {
                return BlocListener<PostBloc, PostState>(
                  listener: (context, state) {
                    if (state is PostDisplaySuccess) {
                      // Fetch comments for each post when posts are loaded
                      for (final post in state.posts) {
                        context
                            .read<CommentBloc>()
                            .add(GetCommentsEvent(post.id));
                      }
                    }
                  },
                  child: const BottomNavigationBarScreen(),
                );
              }

              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
