import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vandacoo/features/auth/presentation/pages/login_page.dart';
import 'package:vandacoo/features/explore_page/presentation/bloc/comments_bloc/comment_bloc.dart';
import 'package:vandacoo/core/common/pages/bottom_navigation_bar_screen.dart';
import 'package:vandacoo/features/messages/presentation/bloc/message_bloc.dart';
import 'package:vandacoo/features/messages/presentation/bloc/users_bloc.dart';
import 'package:vandacoo/core/theme/bloc/theme_bloc.dart';
import 'package:vandacoo/core/theme/bloc/theme_state.dart';
import 'core/common/widgets/loader.dart';
import 'core/utils/show_snackbar.dart';
import 'features/explore_page/presentation/bloc/post_bloc/post_bloc.dart';
import 'package:vandacoo/features/likes/presentation/bloc/like_bloc.dart';
import 'features/upload_media_page/presentation/bloc/upload/upload_bloc.dart';
import 'init_dependencies.dart';

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

  // Initialize plugins and services
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
        create: (_) => serviceLocator<MessageBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<UsersBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<LikeBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<ThemeBloc>(),
      ),
      BlocProvider(
        create: (_) => serviceLocator<UploadBloc>(),
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
          home: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              // Handle auth state changes if needed
              if (state is AuthFailure) {
                showSnackBar(context, state.message);
              }
              if (state is AuthSuccess) {
                context.read<CommentBloc>().add(GetAllCommentsEvent());
              }
            },
            builder: (context, authState) {
              // Only handle authentication-specific states here
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

              // Default to login screen for other states
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
