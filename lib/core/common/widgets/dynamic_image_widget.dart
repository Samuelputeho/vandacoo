import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:async';

class DynamicImageWidget extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final double? maxHeight;
  final double? minHeight;
  final double? maxWidth;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool maintainAspectRatio;
  final BoxFit fit;
  final bool forceFullWidth;

  const DynamicImageWidget({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.maxHeight = 400,
    this.minHeight = 200,
    this.maxWidth,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.maintainAspectRatio = false,
    this.fit = BoxFit.cover,
    this.forceFullWidth = true,
  }) : assert(imageUrl != null || imageFile != null,
            'Either imageUrl or imageFile must be provided');

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveMaxWidth = maxWidth ?? screenWidth;

    if (imageFile != null) {
      return _buildFileImage(effectiveMaxWidth);
    } else {
      return _buildNetworkImage(effectiveMaxWidth);
    }
  }

  Widget _buildFileImage(double effectiveMaxWidth) {
    if (!maintainAspectRatio || forceFullWidth) {
      // Use consistent sizing for all images
      return Container(
        width: effectiveMaxWidth,
        height: maxHeight,
        constraints: BoxConstraints(
          maxWidth: effectiveMaxWidth,
          maxHeight: maxHeight ?? double.infinity,
          minHeight: minHeight ?? 0,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Image.file(
            imageFile!,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }

    return FutureBuilder<Size>(
      future: _getImageSize(imageFile!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final imageSize = snapshot.data!;
          final aspectRatio = imageSize.width / imageSize.height;

          double displayWidth = effectiveMaxWidth;
          double displayHeight = displayWidth / aspectRatio;

          // Constrain height within bounds
          if (maxHeight != null && displayHeight > maxHeight!) {
            displayHeight = maxHeight!;
            displayWidth = displayHeight * aspectRatio;
          }

          if (minHeight != null && displayHeight < minHeight!) {
            displayHeight = minHeight!;
            displayWidth = displayHeight * aspectRatio;
          }

          return Container(
            width: forceFullWidth ? effectiveMaxWidth : displayWidth,
            height: displayHeight,
            constraints: BoxConstraints(
              maxWidth: effectiveMaxWidth,
              maxHeight: maxHeight ?? double.infinity,
              minHeight: minHeight ?? 0,
            ),
            child: ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.zero,
              child: Image.file(
                imageFile!,
                fit: forceFullWidth ? fit : BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          );
        }

        return Container(
          width: effectiveMaxWidth,
          height: minHeight ?? 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: borderRadius,
          ),
          child:
              placeholder ?? const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildNetworkImage(double effectiveMaxWidth) {
    final cleanUrl = (imageUrl ?? '').trim().replaceAll(RegExp(r'\s+'), '');

    if (cleanUrl.isEmpty || cleanUrl.contains('example.com/dummy')) {
      return Container(
        width: effectiveMaxWidth,
        height: minHeight ?? 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius,
        ),
        child: errorWidget ?? _buildDefaultErrorWidget(),
      );
    }

    return CachedNetworkImage(
      imageUrl: cleanUrl,
      imageBuilder: (context, imageProvider) {
        if (!maintainAspectRatio || forceFullWidth) {
          // Use consistent sizing for all images
          return Container(
            width: effectiveMaxWidth,
            height: maxHeight,
            constraints: BoxConstraints(
              maxWidth: effectiveMaxWidth,
              maxHeight: maxHeight ?? double.infinity,
              minHeight: minHeight ?? 0,
            ),
            child: ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.zero,
              child: Image(
                image: imageProvider,
                fit: fit,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          );
        }

        return FutureBuilder<Size>(
          future: _getNetworkImageSize(imageProvider),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final imageSize = snapshot.data!;
              final aspectRatio = imageSize.width / imageSize.height;

              double displayWidth = effectiveMaxWidth;
              double displayHeight = displayWidth / aspectRatio;

              // Constrain height within bounds
              if (maxHeight != null && displayHeight > maxHeight!) {
                displayHeight = maxHeight!;
                displayWidth = displayHeight * aspectRatio;
              }

              if (minHeight != null && displayHeight < minHeight!) {
                displayHeight = minHeight!;
                displayWidth = displayHeight * aspectRatio;
              }

              return Container(
                width: forceFullWidth ? effectiveMaxWidth : displayWidth,
                height: displayHeight,
                constraints: BoxConstraints(
                  maxWidth: effectiveMaxWidth,
                  maxHeight: maxHeight ?? double.infinity,
                  minHeight: minHeight ?? 0,
                ),
                child: ClipRRect(
                  borderRadius: borderRadius ?? BorderRadius.zero,
                  child: Image(
                    image: imageProvider,
                    fit: forceFullWidth ? fit : BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              );
            }

            return Container(
              width: effectiveMaxWidth,
              height: minHeight ?? 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: borderRadius,
              ),
              child: placeholder ??
                  const Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
      placeholder: (context, url) => Container(
        width: effectiveMaxWidth,
        height: minHeight ?? 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius,
        ),
        child: placeholder ?? const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        width: effectiveMaxWidth,
        height: minHeight ?? 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius,
        ),
        child: errorWidget ?? _buildDefaultErrorWidget(),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 8),
        Text(
          'Image not available',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<Size> _getImageSize(File imageFile) async {
    final image = await decodeImageFromList(await imageFile.readAsBytes());
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  Future<Size> _getNetworkImageSize(ImageProvider imageProvider) async {
    final Completer<Size> completer = Completer<Size>();
    final ImageStream stream =
        imageProvider.resolve(const ImageConfiguration());

    late ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      ));
      stream.removeListener(listener);
    });

    stream.addListener(listener);
    return completer.future;
  }
}
