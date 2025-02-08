part of 'init_dependencies.dart';

final serviceLocator = GetIt.instance;

Future<void> initdependencies() async {
  _initAuth();
  _initExplorePage();
  _initMessage();
  _initLikes();
  _initTheme();
  _initUpload();
  _initBookmarkCubit();
  _initGlobalComments();
  final supabase = await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseKey,
  );

  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerLazySingleton(() => prefs);
  serviceLocator.registerLazySingleton(() => supabase.client);

  serviceLocator.registerLazySingleton(() => AppUserCubit());
}

void _initGlobalComments() {
  // Data Sources
  serviceLocator.registerFactory<GlobalCommentsRemoteDatasource>(
    () => GlobalCommentsRemoteDatasourceImpl(
      supabaseClient: serviceLocator(),
    ),
  );

  // Repository
  serviceLocator.registerFactory<GlobalCommentsRepository>(
    () => GlobalCommentsRepositoryImpl(
      remoteDatasource: serviceLocator(),
    ),
  );

  // Use Cases
  serviceLocator.registerFactory(
    () => GlobalCommentsGetCommentUsecase(
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => GlobalCommentsAddCommentUseCase(
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => GlobalCommentsGetAllCommentsUsecase(
      repository: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => GlobalCommentsDeleteCommentUsecase(
      repository: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => BookMarkGetAllPostsUsecase(
      serviceLocator(),
    ),
  );

  // Bloc
  serviceLocator.registerFactory(
    () => GlobalCommentsBloc(
      getCommentsUsecase: serviceLocator(),
      addCommentUsecase: serviceLocator(),
      getAllCommentsUseCase: serviceLocator(),
      deleteCommentUseCase: serviceLocator(),
      getAllPostsUseCase: serviceLocator(),
    ),
  );
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

void _initExplorePage() {
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
    ..registerFactory<BookmarkRemoteDataSource>(
      () => BookmarkRemoteDataSourceImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<BookmarkRepository>(
      () => BookmarkRepositoryImpl(
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
      () => DeletePostUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetCommentsUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => AddCommentUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetAllCommentsUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => DeleteCommentUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UpdatePostCaptionUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetViewedStoriesUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => ToggleBookmarkUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetBookmarkedPostsUseCase(
        serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => ExploreBookmarkBloc(
        toggleBookmarkUseCase: serviceLocator(),
        getBookmarkedPostsUseCase: serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => PostBloc(
        uploadPost: serviceLocator(),
        getAllPostsUsecase: serviceLocator(),
        markStoryViewedUsecase: serviceLocator(),
        getViewedStoriesUsecase: serviceLocator(),
        prefs: serviceLocator(),
        deletePostUseCase: serviceLocator(),
        updatePostCaptionUseCase: serviceLocator(),
        toggleBookmarkUseCase: serviceLocator(),
        getBookmarkedPostsUseCase: serviceLocator(),
      ),
    )
    ..registerFactory(
      () => CommentBloc(
        getCommentsUsecase: serviceLocator(),
        addCommentUsecase: serviceLocator(),
        getAllCommentsUseCase: serviceLocator(),
        deleteCommentUseCase: serviceLocator(),
      ),
    );
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
    () => DeleteMessageThreadUsecase(
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => MarkMessageReadUsecase(
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => GetMessagesUsecase(
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => DeleteMessageUsecase(
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
      deleteMessageThreadUsecase: serviceLocator(),
      markMessageReadUsecase: serviceLocator(),
      getAllUsersUsecase: serviceLocator(),
      deleteMessageUsecase: serviceLocator(),
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

void _initBookmarkCubit() {
  serviceLocator.registerLazySingleton(
    () => BookmarkCubit(
      prefs: serviceLocator(),
      getBookmarkedPostsUseCase: serviceLocator(),
    ),
  );
}
