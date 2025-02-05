import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/session.dart';

class ExportService {
  static Future<void> runFFmpegCommand(
    String command, {
    required void Function(Statistics) onProgress,
    required void Function(File) onCompleted,
    required void Function(Object, StackTrace) onError,
  }) async {
    try {
      // Create the FFmpeg session with progress enabled
      final session = await FFmpegKit.executeAsync(
        command,
        (Session session) async {
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            // Extract the output path from the command
            final parts = command.split(' ');
            String? outputPath;
            for (var i = parts.length - 1; i >= 0; i--) {
              if (parts[i].endsWith('.mp4') || parts[i].endsWith("'")) {
                outputPath = parts[i].replaceAll("'", '');
                break;
              }
            }

            if (outputPath == null) {
              throw Exception('Could not determine output path from command');
            }

            final outputFile = File(outputPath);
            if (!outputFile.existsSync()) {
              throw Exception('Output file was not created');
            }

            onCompleted(outputFile);
          } else {
            final logs = await session.getLogs();
            throw Exception(logs.map((e) => e.getMessage()).join('\n'));
          }
        },
        null, // No log callback needed
        (Statistics statistics) {
          onProgress(statistics);
        },
      );

      // Wait for completion
      await session.getReturnCode();
    } catch (e, s) {
      onError(e, s);
    }
  }

  static void dispose() {
    // Clean up any resources if needed
  }
}
