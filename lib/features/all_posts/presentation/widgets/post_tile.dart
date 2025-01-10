import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vandacoo/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:vandacoo/features/comments/domain/bloc/bloc/comment_bloc.dart';
import 'package:vandacoo/features/likes/presentation/bloc/like_bloc.dart';

class PostTile extends StatefulWidget {
  final String proPic;
  final String name;
  final String postPic;
  final String description;
  final String id;
  final String posterId;
  final String? videoUrl;

  const PostTile({
    super.key,
    required this.proPic,
    required this.name,
    required this.postPic,
    required this.description,
    required this.id,
    required this.posterId,
    this.videoUrl,
  });

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _commentController = TextEditingController();
  bool _showComments = false;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    context.read<LikeBloc>().add(GetLikesEvent(widget.id));
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl!),
      );

      try {
        await _videoController!.initialize();
        // Add listener to update UI when video state changes
        _videoController!.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
        setState(() {});
      } catch (e) {
        print('Error initializing video: $e');
      }
    }
  }

  void _toggleVideo() {
    if (_videoController != null) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
          _isPlaying = false;
        } else {
          _videoController!.play();
          _isPlaying = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
    if (_showComments) {
      context.read<CommentBloc>().add(GetCommentsEvent(widget.id));
    }
  }

  void _submitComment() {
    if (_commentController.text.isNotEmpty) {
      final userId =
          (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
      context.read<CommentBloc>().add(
            AddCommentEvent(
              posterId: widget.id,
              userId: userId,
              comment: _commentController.text,
            ),
          );
      _commentController.clear();
    }
  }

  void _toggleLike() {
    final userId =
        (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
    context.read<LikeBloc>().add(
          ToggleLikeEvent(
            postId: widget.id,
            userId: userId,
          ),
        );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 300,
        color: Colors.white,
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    if (imageUrl.isEmpty) return _buildShimmer();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: 300,
      memCacheWidth: 1080,
      maxWidthDiskCache: 1080,
      maxHeightDiskCache: 1350,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 500),
      fadeOutDuration: const Duration(milliseconds: 500),
      cacheKey: imageUrl,
      placeholder: (context, url) => _buildShimmer(),
      errorWidget: (context, url, error) {
        print('Error loading image: $url, Error: $error');
        return Container(
          width: double.infinity,
          height: 300,
          color: Colors.grey[300],
          child: const Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildProfileImage() {
    if (widget.proPic.isEmpty) {
      return const Icon(Icons.person, color: Colors.grey);
    }

    return CachedNetworkImage(
      imageUrl: widget.proPic,
      fit: BoxFit.cover,
      width: 40,
      height: 40,
      memCacheWidth: 80,
      maxWidthDiskCache: 80,
      maxHeightDiskCache: 80,
      cacheKey: widget.proPic,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) {
        print('Error loading profile image: $url, Error: $error');
        return const Icon(Icons.person, color: Colors.grey);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: widget.proPic.isNotEmpty
                        ? _buildProfileImage()
                        : const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Post Media (Image or Video)
          if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty)
            _videoController?.value.isInitialized == true
                ? GestureDetector(
                    onTap: _toggleVideo,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              VideoPlayer(_videoController!),
                              AnimatedOpacity(
                                opacity:
                                    !_isPlaying && widget.postPic.isNotEmpty
                                        ? 1.0
                                        : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: widget.postPic.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: widget.postPic,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 1080,
                                        placeholder: (context, url) =>
                                            _buildShimmer(),
                                        errorWidget: (context, url, error) {
                                          print(
                                              'Error loading video thumbnail: $url, Error: $error');
                                          return Container(
                                            color: Colors.black,
                                          );
                                        },
                                      )
                                    : Container(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: !_isPlaying ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.postPic.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: widget.postPic,
                            fit: BoxFit.cover,
                            memCacheWidth: 1080,
                            placeholder: (context, url) => _buildShimmer(),
                            errorWidget: (context, url, error) {
                              print(
                                  'Error loading video thumbnail: $url, Error: $error');
                              return Container(color: Colors.black);
                            },
                          ),
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ],
                    ),
                  )
          else if (widget.postPic.isNotEmpty)
            _buildNetworkImage(widget.postPic),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BlocBuilder<LikeBloc, Map<String, LikeState>>(
                      builder: (context, likeStates) {
                        final userId = (context.read<AppUserCubit>().state
                                as AppUserLoggedIn)
                            .user
                            .id;
                        final likeState = likeStates[widget.id];
                        bool isLiked = false;
                        int likeCount = 0;

                        if (likeState is LikeSuccess) {
                          isLiked = likeState.likedByUsers.contains(userId);
                          likeCount = likeState.likedByUsers.length;
                        }

                        return Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : null,
                              ),
                              onPressed: _toggleLike,
                            ),
                            Text(
                              '$likeCount',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: _toggleComments,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Description
          if (widget.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                widget.description,
                style: const TextStyle(fontSize: 14),
              ),
            ),

          // Comments Section
          if (_showComments)
            BlocBuilder<CommentBloc, CommentState>(
              builder: (context, state) {
                if (state is CommentLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (state is CommentFailure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Error: ${state.error}'),
                    ),
                  );
                }

                if (state is CommentDisplaySuccess) {
                  return Column(
                    children: [
                      // Comment list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.comments.length,
                        itemBuilder: (context, index) {
                          final comment = state.comments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundImage: comment.userProPic != null &&
                                          comment.userProPic!.isNotEmpty
                                      ? NetworkImage(comment.userProPic!)
                                      : const AssetImage('assets/user1.jpeg')
                                          as ImageProvider,
                                  radius: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.userName ?? 'Anonymous',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(comment.comment),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Comment input
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a comment...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _submitComment,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),

          const Divider(),
        ],
      ),
    );
  }
}
