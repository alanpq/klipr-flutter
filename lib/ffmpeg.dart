import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:process_run/shell.dart';

import 'package:klipr/stream.dart';
import 'package:path/path.dart';

class FFmpeg extends ChangeNotifier {
  final _ffmpegOut = StreamController<List<int>>();
  final _ffmpegErr = StreamController<List<int>>();

  late String _ffmpeg;
  late String _ffprobe;

  int pass = 0;
  int frameCount = 0;
  double progress = 0.0;
  bool isRunning = false;

  double _ratio = 1.0;
  late Shell _shell;

  FFmpeg() {
    var lib = join(File(Platform.resolvedExecutable).parent.path, "ffmpeg");
    _ffmpeg = join(lib, "ffmpeg.exe");
    _ffprobe = join(lib, "ffprobe.exe");

    if (kDebugMode) {
      print('Lib folder: $lib');
      print("Found ffmpeg at '$_ffmpeg'");
      print("Found ffprobe at '$_ffprobe'");
    }

    streamLines(_ffmpegOut.stream).listen((line) {
      var split = line.split("=");
      if (split.length == 2) {
        var key = split[0];
        var value = split[1];
        switch (key) {
          case "progress":
            if (value == "end") {
              if (pass == 1) {
                // we finished 2nd pass, whole export is done
                isRunning = false;
                progress = 1.0;
              }
              pass += 1;
            }
            break;
          case "frame":
            if (kDebugMode) {
              print("got frame=$value, out of $frameCount frames");
            }
            progress = (int.parse(value) + frameCount * pass) /
                (frameCount * 2 * _ratio); // * 2 because 2-pass export
            break;
        }
      } else {
        if (line.startsWith("FRAMES:")) {
          frameCount = int.parse(line.substring(7));
          if (kDebugMode) {
            print("$frameCount frames");
          }
        } else {
          print(line);
        }
      }
      notifyListeners();
    });
    streamLines(_ffmpegErr.stream).listen((line) {
      print(line);
    });

    _shell = Shell(
        throwOnError: false,
        verbose: false,
        stdout: _ffmpegOut.sink,
        stderr: _ffmpegErr.sink);
  }

  void countFrames(String file) async {
    await _shell.run("""
    echo|set /p="FRAMES:"
    '$_ffprobe' -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 '${join(file)}'
    """);
  }

  /// Starts an ffmpeg export
  ///
  /// `input` is the path to input file.
  ///
  /// `start` and `end` are a percentage in the range [0,1].
  ///
  /// `duration` is length of the file in seconds.
  ///
  /// `size` is in MB.
  ///
  /// `output` is the path to save the export to.
  void export(String input, double start, double end, double duration,
      double size, String output) {
    var startS = start * duration;
    var endS = end * duration;
    var regionLen = (endS - startS);

    countFrames(input);
    _ratio = end - start;

    // note: since we arent reencoding the audio stream, the audio bitrate might not be 128k
    var audioBitrate = 128;
    var videoBitrate = (size * 8192) / regionLen;

    var args =
        "-hide_banner -progress - -nostats -y -i '${join(input)}' -ss $startS -to $endS -c:v libx264 -b:v ${videoBitrate - audioBitrate}k";
    _shell.run(
      """
      '$_ffmpeg' $args -pass 1 -vsync cfr -f null NULL
      '$_ffmpeg' $args -pass 2 -c:a copy '$output'
      """,
    );

    isRunning = true;
    pass = 0;
    notifyListeners();
  }

  void cancel() {
    while (_shell.kill()) {}
    isRunning = false;
    progress = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    while (_shell.kill()) {}
  }
}
