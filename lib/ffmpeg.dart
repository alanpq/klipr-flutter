import 'dart:async';

import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';

import 'package:klipr/stream.dart';

class FFmpeg {
  final _ffmpegOut = StreamController<List<int>>();
  final _ffmpegErr = StreamController<List<int>>();

  final void Function(double progress)? onProgress;
  final void Function()? onStart;
  final void Function()? onEnd;

  late Shell _shell;

  FFmpeg({this.onProgress, this.onStart, this.onEnd});

  void init() {
    streamLines(_ffmpegOut.stream).listen((line) {
      print(line);
    });

    _shell = Shell(
        throwOnError: false,
        verbose: false,
        stdout: _ffmpegOut.sink,
        stderr: _ffmpegErr.sink);
  }

  /// Starts an ffmpeg export
  ///
  /// `input` is the path to input file.
  ///
  /// `start` and `end` are in seconds.
  ///
  /// `size` is in MB.
  ///
  /// `output` is the path to save the export to.
  void export(
      String input, double start, double end, double size, String output) {
    var regionLen = (end - start);

    // note: since we arent reencoding the audio stream, the audio bitrate might not be 128k
    var audioBitrate = 128;
    var videoBitrate = (size * 8192) / regionLen;

    var args =
        "-hide_banner -progress - -nostats -y -i '${input}' -ss ${start} -to ${end} -c:v libx264 -b:v ${videoBitrate - audioBitrate}k";
    _shell.run(
      """
      "ffmpeg/ffmpeg.exe" ${args} -pass 1 -vsync cfr -f null NULL
      "ffmpeg/ffmpeg.exe" ${args} -pass 2 -c:a copy ${output}
      """,
    );

    if (onStart != null) onStart!();
  }
}
