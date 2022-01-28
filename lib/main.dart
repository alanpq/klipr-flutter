import 'dart:async';
import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:klipr/controls.dart';
import 'package:klipr/sidebar.dart';
import 'package:klipr/stream.dart';
import 'package:klipr/timeline.dart';
import 'package:cross_file/cross_file.dart';
import 'package:process_run/cmd_run.dart';
import 'package:process_run/shell.dart';

void main() {
  DartVLC.initialize();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  XFile? _file;
  final Player _player = Player(id: 1234);

  double _start = 0.0;
  double _end = 1.0;

  late Shell _shell;

  final _ffmpegOut = StreamController<List<int>>();
  final _ffmpegErr = StreamController<List<int>>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    streamLines(_ffmpegOut.stream).listen((line) {
      print(line);
    });

    _shell = Shell(
        throwOnError: false,
        verbose: false,
        stdout: _ffmpegOut.sink,
        stderr: _ffmpegErr.sink);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        darkTheme: ThemeData.dark(),
        title: "hi",
        home: Scaffold(
            body: Row(children: [
          Expanded(
              flex: 2,
              child: Main(
                player: _player,
                onFile: (XFile file) => _file = file,
                onChangeRegion: (start, end) {
                  _start = start;
                  _end = end;
                },
              )),
          Expanded(
              flex: 1,
              child: Sidebar(
                onExport: (double size) async {
                  var len = _player.position.duration!.inMicroseconds / 1000000;
                  var start = _start * len;
                  var end = _end * len;
                  var regionLen = (end - start);

                  // note: since we arent reencoding the audio stream, the audio bitrate might not be 128k
                  var audioBitrate = 128;
                  var videoBitrate = (size * 8192) / regionLen;

                  var args =
                      "-hide_banner -progress - -nostats -y -i '${_file!.path}' -ss ${start} -to ${end} -c:v libx264 -b:v ${videoBitrate - audioBitrate}k";

                  _player.stop();
                  _shell.run(
                    """
                    "ffmpeg/ffmpeg.exe" ${args} -pass 1 -vsync cfr -f null NULL
                    "ffmpeg/ffmpeg.exe" ${args} -pass 2 -c:a copy out.mp4
                    echo DONE
                    """,
                  );
                  print('DONE');
                  print('${regionLen} seconds');
                  print('TARGET SIZE: ${size}M');
                  print('BITRATE: ${videoBitrate}');
                  // var proc = ProcessCmd("ffmpeg/ffmpeg.exe", ["-version"]);
                  // var proc = ProcessCmd("./ffmpeg/ffmpeg.exe", [
                  //   // "-ss ${(_start * len).round()}us",
                  //   // "-to ${(_end * len).round()}us",
                  //   // "-i '${_file!.path}'",
                  //   // "-c copy",
                  //   // "out.mp4",
                  // ]);
                  // await runCmd(proc, verbose: true);
                },
              ))
        ])));
  }
}

class Main extends StatefulWidget {
  final Player player;
  final OnChangeRegionFunc onChangeRegion;
  final void Function(XFile file) onFile;

  const Main(
      {Key? key,
      required this.player,
      required this.onFile,
      required this.onChangeRegion})
      : super(key: key);

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  XFile? _file;
  bool _dragging = false;

  Offset? offset;
  double _time = 0.0;

  double _start = 0.0;
  double _end = 1.0;

  bool _playAnyway = false;

  Widget dropOrVideo(BuildContext context) {
    var drop = DropTarget(
        onDragDone: (details) async {
          if (details.files.isEmpty) return;
          _file = details.files.first;
          widget.onFile(_file!);
          widget.player.open(Media.file(File(details.files.first.path)));
        },
        onDragUpdated: (details) {
          setState(() {
            offset = details.localPosition;
          });
        },
        onDragEntered: (detail) {
          setState(() {
            _dragging = true;
            offset = detail.localPosition;
          });
        },
        onDragExited: (detail) {
          setState(() {
            _dragging = false;
            offset = null;
          });
        },
        child: Align(
            alignment: Alignment.center,
            child: Container(
                decoration: BoxDecoration(
                    color: _dragging
                        ? Colors.black.withAlpha(20)
                        : Colors.transparent),
                child: const Text("Drop a video here to open."))));

    if (_file == null) {
      return drop;
    } else {
      return Stack(
        children: [
          drop,
          Video(
            player: widget.player,
            showControls: false,
          )
        ],
      );
    }
  }

  @override
  void initState() {
    super.initState();
    widget.player.setVolume(0.5);
    widget.player.positionStream.listen((PositionState state) {
      setState(() {
        _time = state.position!.inMicroseconds.toDouble() /
            state.duration!.inMicroseconds.toDouble();
      });
      if (_time >= _end && !_playAnyway) {
        widget.player.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 2, child: dropOrVideo(context)),
        Controls(
          onVolume: (volume) {
            widget.player.setVolume(volume);
          },
        ),
        Timeline(
          externTime: _time,
          onScrub: (time) {
            setState(() {
              _time = time;
              if (_time > _end) {
                _playAnyway = true;
              } else {
                _playAnyway = false;
              }
            });
            widget.player.seek(Duration(
                microseconds:
                    (widget.player.position.duration!.inMicroseconds * time)
                        .toInt()));
            if (!widget.player.playback.isPlaying) {
              widget.player.play();
            }
          },
          onChangeRegion: (start, end) {
            setState(() {
              _start = start;
              _end = end;
            });
            widget.onChangeRegion(start, end);
          },
        ),
        Text("start: $_start end: $_end time: $_time"),
      ],
    );
  }
}
