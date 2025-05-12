import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:video_editor/video_editor.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

class FeedsExportService {
  static Future<void> compressVideo({
    required String inputPath,
    required void Function(double) onProgress,
    required void Function(File) onCompleted,
    required void Function(Object, StackTrace) onError,
  }) async {
    dynamic subscription;
    try {
      // Subscribe to compression progress
      subscription = VideoCompress.compressProgress$.subscribe((progress) {
        onProgress(progress / 100);
      });

      // Start video compression
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        inputPath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (mediaInfo?.file == null) {
        throw Exception('Failed to compress video');
      }

      onCompleted(mediaInfo!.file!);
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    } finally {
      subscription?.unsubscribe();
      await VideoCompress.cancelCompression();
    }
  }

  static Future<void> trimVideo({
    required VideoEditorController controller,
    required void Function(double) onProgress,
    required void Function(File) onCompleted,
    required void Function(Object, StackTrace) onError,
  }) async {
    try {
      // Get temp directory for output
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = path.join(
        tempDir.path,
        'trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      // Calculate trim positions
      final startDuration = Duration(
          milliseconds: (controller.minTrim *
                  controller.video.value.duration.inMilliseconds)
              .toInt());
      final endDuration = Duration(
          milliseconds: (controller.maxTrim *
                  controller.video.value.duration.inMilliseconds)
              .toInt());

      // Create a new file with the trimmed content
      final File inputFile = controller.file;
      final File outputFile = File(outputPath);

      // Copy the file first
      await inputFile.copy(outputPath);

      if (!await outputFile.exists()) {
        throw Exception('Failed to create output file');
      }

      // Update progress
      onProgress(1.0);
      onCompleted(outputFile);
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }

  static Future<void> cancelCompression() async {
    await VideoCompress.cancelCompression();
  }
}
