import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:klipr/controls.dart';
import 'package:klipr/ffmpeg.dart';
import 'package:klipr/sidebar.dart';
import 'package:klipr/timeline.dart';
import 'package:cross_file/cross_file.dart';
import 'package:provider/provider.dart';

void main() {
  DartVLC.initialize();
  runApp(ChangeNotifierProvider(
    create: (context) => FFmpeg(),
    child: const App(),
  ));
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
                var ffmpeg = Provider.of<FFmpeg>(context, listen: false);
                var len = _player.position.duration!.inMicroseconds / 1000000;
                String? res = await FilePicker.platform.saveFile(
                  dialogTitle: "Export as",
                  type: FileType.custom,
                  allowedExtensions: [".mp4"],
                  lockParentWindow: true,
                  // fileName: _file!.name,
                );
                if (res != null) {
                  var split = res.split(".");
                  if (split.length == 1 || split.last != "mp4") {
                    split.add("mp4");
                    res = split.join(".");
                  }
                  _player.stop();
                  ffmpeg.export(_file!.path, _start, _end, len, size, res);
                }
              },
            ),
          )
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
