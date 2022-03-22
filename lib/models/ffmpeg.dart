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

  List<String> error = [];

  int pass = 0;
  int frameCount = 0;
  double _effectiveFrameCount = 0;
  double progress = 0.0;
  bool isRunning = false;
  bool isError = false;

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
      error.add(line);
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
            var eFrame = int.parse(value) + _effectiveFrameCount * pass;
            // if (kDebugMode) {
            //   print(line);
            //   print(
            //       "got frame=$value (aka $eFrame), out of ${_effectiveFrameCount * 2} effective frames");
            // }
            progress = eFrame /
                (_effectiveFrameCount * 2); // * 2 because 2-pass export
            break;
        }
      } else {
        if (line.startsWith("FRAMES:")) {
          frameCount = int.parse(line.substring(7));
          _effectiveFrameCount = frameCount * _ratio;
          if (kDebugMode) {
            print(
                "$frameCount frames @ ratio $_ratio -> $_effectiveFrameCount effective frames");
          }
        } else if (kDebugMode) {
          print("[IN] $line");
        }
      }
      notifyListeners();
    });
    streamLines(_ffmpegErr.stream).listen((line) {
      var split = line.split("=");
      if (split.length != 2) {
        isError = true;
        error.add(line);
      }
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
  bool export(String input, double start, double end, double duration,
      double size, String output) {
    error.clear();
    if (duration == 0) return false;
    var startS = start * duration;
    var endS = end * duration;
    var regionLen = (endS - startS);

    _ratio = end - start;
    countFrames(input);

    // note: since we arent reencoding the audio stream, the audio bitrate might not be 128k
    var audioBitrate = 128;
    var videoBitrate = (size * 8192) / regionLen;

    // if (kDebugMode) {
    error.add('================');
    error.add("region length: $regionLen seconds (ratio: $_ratio)");
    error.add("$startS secs -> $endS secs ($start->$end)");
    error.add("duration: $duration");
    error.add("");
    error.add("audio bitrate: $audioBitrate");
    error.add("video bitrate: $videoBitrate");
    error.add("target size: $size");
    error.add('================');
    // }

    var args =
        "-hide_banner -progress pipe:1 -nostats -y -i '${join(input)}' -ss $startS -to $endS -c:v libx264 -b:v ${videoBitrate - audioBitrate}k";
    _shell.run(
      """
      '$_ffmpeg' $args -pass 1 -vsync cfr -f null NULL
      '$_ffmpeg' $args -pass 2 -c:a copy '$output'
      """,
    );

    isRunning = true;
    pass = 0;
    notifyListeners();

    return true;
  }

  void _kill() {
    try {
      _shell.kill(ProcessSignal.sigkill);
    } catch (e) {
      print('error while killing: $e');
    }
  }

  void cancel() {
    isRunning = false;
    progress = 0.0;
    notifyListeners();
    _kill();
  }

  @override
  void dispose() {
    super.dispose();
    _kill();
  }
}
