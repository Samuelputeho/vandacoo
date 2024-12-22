import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/core/theme/bloc/theme_bloc.dart';
import 'package:vandacoo/features/all_posts/data/datasources/post_remote_data_source.dart';
import 'package:vandacoo/features/all_posts/data/repository/post_repository_impl.dart';
import 'package:vandacoo/features/all_posts/domain/usecases/get_all_posts_usecase.dart';
import 'package:vandacoo/features/all_posts/domain/usecases/upload_post_usecase.dart';
import 'package:vandacoo/features/all_posts/presentation/bloc/post_bloc.dart';
import 'package:vandacoo/features/auth/domain/repository/auth_repository.dart';
import 'package:vandacoo/features/auth/domain/usecase/get_all_users.dart';
import 'package:vandacoo/features/auth/domain/usecase/logout_usecase.dart';
import 'package:vandacoo/features/auth/domain/usecase/update_user_usecase.dart';
import 'package:vandacoo/features/auth/domain/usecase/update_has_seen_intro_video_usecase.dart';
import 'package:vandacoo/features/comments/data/repository/comment_repository_impl.dart';
import 'package:vandacoo/features/comments/domain/bloc/bloc/comment_bloc.dart';
import 'package:vandacoo/features/comments/domain/repository/comment_reposirory.dart';
import 'package:vandacoo/features/comments/domain/usecase/add_comment_usecase.dart';
import 'package:vandacoo/features/comments/domain/usecase/get_comment_usecase.dart';
import 'package:vandacoo/features/likes/data/datasources/like_remote_data_source.dart';
import 'package:vandacoo/features/likes/data/repository/like_repository_impl.dart';
import 'package:vandacoo/features/likes/domain/repository/like_repository.dart';
import 'package:vandacoo/features/likes/presentation/bloc/like_bloc.dart';
import 'package:vandacoo/screens/messages/data/datasources/message_remote_data_source.dart';
import 'package:vandacoo/screens/messages/data/repository/message_reposity_impl.dart';
import 'package:vandacoo/screens/messages/domain/repository/message_repository.dart';
import 'package:vandacoo/screens/messages/domain/usecase/get_mesaages_usecase.dart';
import 'package:vandacoo/screens/messages/domain/usecase/send_message_usecase.dart';
import 'package:vandacoo/screens/messages/presentation/bloc/message_bloc.dart';

import 'core/secrets/app_secrets.dart';
import 'features/all_posts/domain/repository/post_repository.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecase/current_user.dart';
import 'features/auth/domain/usecase/user_login.dart';
import 'features/auth/domain/usecase/user_sign_up.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/comments/data/datasources/comment_remote_data_source.dart';

final serviceLocator = GetIt.instance;

Future<void> initdependencies() async {
  _initAuth();
  _initPost();
  _initComment();
  _initMessage();
  _initLikes();
  _initTheme();

  final supabase = await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseKey,
  );
  serviceLocator.registerLazySingleton(() => supabase.client);

  serviceLocator.registerLazySingleton(() => AppUserCubit());
}

void _initAuth() {
  serviceLocator
    ..registerFactory<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UserSignUp(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UserLogin(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => CurrentUser(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetAllUsers(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => LogoutUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UpdateUserProfile(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UpdateHasSeenIntroVideo(
        serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => AuthBloc(
        logoutUsecase: serviceLocator(),
        userSignUp: serviceLocator(),
        userLogin: serviceLocator(),
        currentUser: serviceLocator(),
        appUserCubit: serviceLocator(),
        getAllUsers: serviceLocator(),
        updateUserProfile: serviceLocator(),
        updateHasSeenIntroVideo: serviceLocator(),
      ),
    );
}

void _initPost() {
  serviceLocator
    ..registerFactory<PostRemoteDataSource>(
      () => PostRemoteDataSourceImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<PostRepository>(
      () => PostRepositoryImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UploadPost(
        postRepository: serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetAllPostsUsecase(
        serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => PostBloc(
        uploadPost: serviceLocator(),
        getAllPostsUsecase: serviceLocator(),
      ),
    );
}

void _initComment() {
  // Data Sources
  if (!serviceLocator.isRegistered<CommentRemoteDataSource>()) {
    serviceLocator.registerLazySingleton<CommentRemoteDataSource>(
      () => CommentRemoteDataSourceImpl(serviceLocator()),
    );
  }

  // Repositories
  if (!serviceLocator.isRegistered<CommentRepository>()) {
    serviceLocator.registerLazySingleton<CommentRepository>(
      () => CommentRepositoryImpl(remoteDataSource: serviceLocator()),
    );
  }

  // Use Cases
  if (!serviceLocator.isRegistered<GetCommentsUsecase>()) {
    serviceLocator
        .registerLazySingleton(() => GetCommentsUsecase(serviceLocator()));
  }
  if (!serviceLocator.isRegistered<AddCommentUsecase>()) {
    serviceLocator
        .registerLazySingleton(() => AddCommentUsecase(serviceLocator()));
  }

  // Bloc
  if (!serviceLocator.isRegistered<CommentBloc>()) {
    serviceLocator.registerFactory(
      () => CommentBloc(
        getCommentsUsecase: serviceLocator(),
        addCommentUsecase: serviceLocator(),
      ),
    );
  }
}

void _initMessage() {
  // Data Sources
  serviceLocator.registerFactory<MessageRemoteDataSource>(
    () => MessageRemoteDataSourceImpl(
      serviceLocator(),
    ),
  );

  // Repository
  serviceLocator.registerFactory<MessageRepository>(
    () => MessageRepositoryImpl(
      remoteDataSource: serviceLocator(),
    ),
  );

  // Use Cases
  serviceLocator.registerFactory(
    () => SendMessageUsecase(
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => GetMessagesUsecase(
      serviceLocator(),
    ),
  );

  // Bloc
  serviceLocator.registerFactory(
    () => MessageBloc(
      sendMessageUsecase: serviceLocator(),
      getMessagesUsecase: serviceLocator(),
    ),
  );
}

void _initLikes() {
  // Data Sources
  if (!serviceLocator.isRegistered<LikeRemoteDataSource>()) {
    serviceLocator.registerLazySingleton<LikeRemoteDataSource>(
      () => LikeRemoteDataSourceImpl(serviceLocator()),
    );
  }

  // Repository
  if (!serviceLocator.isRegistered<LikeRepository>()) {
    serviceLocator.registerLazySingleton<LikeRepository>(
      () => LikeRepositoryImpl(serviceLocator()),
    );
  }

  // Bloc
  if (!serviceLocator.isRegistered<LikeBloc>()) {
    serviceLocator.registerFactory(
      () => LikeBloc(likeRepository: serviceLocator()),
    );
  }
}

void _initTheme() {
  serviceLocator.registerFactory(() => ThemeBloc());
}
