import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';

class ExportService {
  static Future<void> runFFmpegCommand(
    String command, {
    required void Function(Statistics) onProgress,
    required void Function(File) onCompleted,
    required void Function(Object, StackTrace) onError,
  }) async {
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (returnCode?.isValueSuccess() ?? false) {
        // Extract the output path from the command, handling paths with spaces
        final parts = command.split(' ');
        String? outputPath;
        for (int i = 0; i < parts.length - 1; i++) {
          if (parts[i] == '-c:a' && parts[i + 1] == 'aac') {
            outputPath = parts[i + 2].replaceAll("'", '');
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
    } catch (e, s) {
      onError(e, s);
    }
  }

  static void dispose() {
    // Clean up any resources if needed
  }
}
