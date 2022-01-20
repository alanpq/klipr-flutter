import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:klipr/sidebar.dart';
import 'package:klipr/timeline.dart';
import 'package:cross_file/cross_file.dart';

void main() {
  DartVLC.initialize();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        darkTheme: ThemeData.dark(),
        title: "hi",
        home: Scaffold(
            body: Row(children: const [
          Expanded(flex: 2, child: Main()),
          Expanded(flex: 1, child: Sidebar())
        ])));
  }
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  XFile? file;
  bool _dragging = false;
  final Player _player = Player(id: 1234);

  Offset? offset;
  double _time = 0.0;

  Widget dropOrVideo(BuildContext context) {
    var drop = DropTarget(
        onDragDone: (details) async {
          if (details.files.isEmpty) return;
          file = details.files.first;
          _player.open(Media.file(File(details.files.first.path)));
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

    if (file == null) {
      return drop;
    } else {
      return Stack(
        children: [
          drop,
          Video(
            player: _player,
            showControls: false,
          )
        ],
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _player.positionStream.listen((PositionState state) {
      setState(() {
        _time = state.position!.inMicroseconds.toDouble() /
            state.duration!.inMicroseconds.toDouble();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 2, child: dropOrVideo(context)),
        Expanded(
            flex: 1,
            child: Timeline(
              externTime: _time,
              onScrub: (time) {
                setState(() {
                  _time = time;
                });
                _player.seek(Duration(
                    microseconds:
                        (_player.position.duration!.inMicroseconds * time)
                            .toInt()));
                if (!_player.playback.isPlaying) {
                  _player.play();
                }
              },
            ))
      ],
    );
  }
}
