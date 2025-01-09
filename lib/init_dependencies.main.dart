part of 'init_dependencies.dart';

final serviceLocator = GetIt.instance;

Future<void> initdependencies() async {
  _initAuth();
  _initPost();
  _initComment();
  _initMessage();
  _initLikes();
  _initTheme();
  _initUpload();

  final supabase = await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseKey,
  );

  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerLazySingleton(() => prefs);
  serviceLocator.registerLazySingleton(() => supabase.client);

  serviceLocator.registerLazySingleton(() => AppUserCubit());
}

void _initUpload() {
  serviceLocator.registerFactory<UploadRemoteDataSource>(
    () => UploadRemoteDataSourceImpl(
      serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<UploadRepository>(
    () => UploadRepositoryImpl(
      serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<UploadUseCase>(
    () => UploadUseCase(
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<UploadBloc>(
    () => UploadBloc(uploadUseCase: serviceLocator()),
  );
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
    ..registerFactory(
      () => MarkStoryViewedUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetViewedStoriesUsecase(
        serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => PostBloc(
        uploadPost: serviceLocator(),
        getAllPostsUsecase: serviceLocator(),
        markStoryViewedUsecase: serviceLocator(),
        getViewedStoriesUsecase: serviceLocator(),
        prefs: serviceLocator(),
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

  // get all users
  serviceLocator.registerFactory(
    () => GetAllUsersForMessageUseCase(
      serviceLocator(),
    ),
  );

  // Blocs
  serviceLocator.registerFactory(
    () => MessageBloc(
      sendMessageUsecase: serviceLocator(),
      getMessagesUsecase: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => UsersBloc(
      getAllUsers: serviceLocator(),
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
