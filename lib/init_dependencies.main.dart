part of 'init_dependencies.dart';

final serviceLocator = GetIt.instance;

Future<void> initdependencies() async {
  final supabase = await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseKey,
  );

  // Stripe removed - using DPO for payments instead
  // Stripe.publishableKey = AppSecrets.stripePublishableKey;

  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerLazySingleton(() => prefs);
  serviceLocator.registerLazySingleton(() => supabase.client);
  serviceLocator.registerLazySingleton(() => AppUserCubit());
  serviceLocator.registerLazySingleton(() => StoriesViewedCubit(
        prefs: serviceLocator(),
        globalCommentsBloc: serviceLocator(),
      ));

  _initAuth();
  _initExplorePage();
  _initMessage();
  _initTheme();
  _initUpload();
  _initBookmarkPage();
  _initBookmarkCubit();
  _initGlobalComments();
  _initProfile();
  _initFollowPage();
  _initHomePage();
}

void _initProfile() {
  // Data Sources
  serviceLocator.registerLazySingleton<ProfileRemoteDatasource>(
    () => ProfileRemoteDatasourceImpl(supabase: serviceLocator()),
  );

  // Repositories
  serviceLocator.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDatasource: serviceLocator()),
  );

  // Use Cases
  serviceLocator.registerLazySingleton(
    () => GetPosterForUserUsecase(profileRepository: serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => EditUserInfoUsecase(profileRepository: serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => GetUserInfoUsecase(profileRepository: serviceLocator()),
  );

  // Blocs
  serviceLocator.registerFactory<ProfileBloc>(
    () => ProfileBloc(
      getUserInfoUsecase: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory<EditUserInfoBloc>(
    () => EditUserInfoBloc(
      editUserInfoUsecase: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory<ProfilePostsBloc>(
    () => ProfilePostsBloc(
      getPosterForUserUsecase: serviceLocator(),
    ),
  );
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

  serviceLocator.registerFactory(
    () => GlobalCommentsUpdatePostCaptionUseCase(
      repository: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => GlobalToggleBookmarkUseCase(
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => GlobalToggleLikeUsecase(
      globalCommentsRepository: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => GlobalReportPostUseCase(
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => GlobalDeletePostUseCase(
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => MarkStoryViewedUseCase(
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => GetViewedStoriesUseCase(
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
      updatePostCaptionUseCase: serviceLocator(),
      reportPostUseCase: serviceLocator(),
      toggleLikeUseCase: serviceLocator(),
      prefs: serviceLocator(),
      toggleBookmarkUseCase: serviceLocator(),
      deletePostUseCase: serviceLocator(),
      markStoryViewedUseCase: serviceLocator(),
      getViewedStoriesUseCase: serviceLocator(),
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
    ..registerFactory(
      () => CheckUserStatus(
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
        checkUserStatus: serviceLocator(),
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
      () => explore.UpdatePostCaptionUseCase(
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
      () => ReportPostUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => ToggleLikeUsecase(
        postRepository: serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetBookmarkedPostsUseCase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetCurrentUserInformationUsecase(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => SendMessage(
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
        reportPostUseCase: serviceLocator(),
        toggleLikeUsecase: serviceLocator(),
        getCurrentUserInformationUsecase: serviceLocator(),
      ),
    )
    ..registerFactory(
      () => CommentBloc(
        getCommentsUsecase: serviceLocator(),
        addCommentUsecase: serviceLocator(),
        getAllCommentsUseCase: serviceLocator(),
        deleteCommentUseCase: serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => FollowingBloc(
        getAllPostsUsecase: serviceLocator(),
        getCurrentUserInformationUsecase: serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => SendMessageCommentBloc(
        sendMessageUseCase: serviceLocator(),
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
      messageRepository: serviceLocator(),
    ),
  );
}

void _initTheme() {
  serviceLocator.registerFactory(() => ThemeBloc());
}

void _initBookmarkCubit() {
  serviceLocator.registerLazySingleton(
    () => BookmarkCubit(
      prefs: serviceLocator(),
      getBookmarkedPostsUseCase:
          serviceLocator<BookMarkPageGetBookmarkedPostsUseCase>(),
    ),
  );
}

void _initBookmarkPage() {
  // Data Sources
  serviceLocator.registerFactory<BookmarkPageRemoteDataSource>(
    () => BookmarkPageRemoteDataSourceImpl(
      serviceLocator(),
    ),
  );

  // Repository
  serviceLocator.registerFactory<BookmarkPageRepository>(
    () => BookmarkPageRepositoryImpl(
      serviceLocator(),
    ),
  );

  // Use Cases
  serviceLocator.registerFactory(
    () => BookmarkPageToggleBookmarkUseCase(
      serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => BookMarkPageGetBookmarkedPostsUseCase(
      serviceLocator(),
    ),
  );

  // Bloc
  serviceLocator.registerFactory(
    () => SettingsBookmarkBloc(
      toggleBookmarkUseCase: serviceLocator(),
      getBookmarkedPostsUseCase: serviceLocator(),
    ),
  );
}

void _initFollowPage() {
  // Data Sources
  serviceLocator.registerLazySingleton<FollowPageRemoteDatasource>(
    () => FollowPageRemoteDataSourceImpl(serviceLocator()),
  );

  // Repository
  serviceLocator.registerLazySingleton<FollowPageRepository>(
    () => FollowPageRepositoryImpl(serviceLocator()),
  );

  // Use Cases
  serviceLocator.registerLazySingleton(
    () => FollowUserUsecase(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => UnfollowUserUsecase(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => IsFollowingUseCase(serviceLocator()),
  );
  serviceLocator.registerLazySingleton(
    () => GetUserCountsUsecase(serviceLocator()),
  );

  // Bloc
  serviceLocator.registerFactory(
    () => FollowPageBloc(
      followUserUsecase: serviceLocator(),
      unfollowUserUsecase: serviceLocator(),
      isFollowingUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory(
    () => FollowCountBloc(
      getUserCountsUsecase: serviceLocator(),
    ),
  );
}

void _initHomePage() {
  // Data Sources
  serviceLocator.registerFactory<FeedsRemoteDataSource>(
    () => FeedsRemoteDataSourceImpl(
      serviceLocator(),
    ),
  );

  // Repository
  serviceLocator.registerFactory<FeedsRepository>(
    () => FeedsRepositoryImpl(
      remoteDataSource: serviceLocator(),
    ),
  );

  // Use Cases
  serviceLocator.registerFactory(
    () => UploadFeedsPostUsecase(
      repository: serviceLocator(),
    ),
  );

  // Blocs
  serviceLocator.registerFactory(
    () => FeedsBloc(
      uploadFeedsPostUsecase: serviceLocator(),
    ),
  );
}
