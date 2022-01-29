import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:klipr/controls.dart';
import 'package:klipr/models/clip_region.dart';
import 'package:klipr/models/ffmpeg.dart';
import 'package:klipr/models/video.dart';
import 'package:klipr/sidebar.dart';
import 'package:klipr/timeline.dart';
import 'package:cross_file/cross_file.dart';
import 'package:provider/provider.dart';

void main() {
  DartVLC.initialize();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => FFmpeg()),
      ChangeNotifierProvider(create: (context) => VideoModel()),
      ChangeNotifierProvider(create: (context) => ClipRegionModel()),
    ],
    child: const App(),
  ));
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
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
          const Expanded(flex: 2, child: Main()),
          Expanded(
            flex: 1,
            child: Sidebar(
              onExport: (double size) async {
                var ffmpeg = Provider.of<FFmpeg>(context, listen: false);
                var video = Provider.of<VideoModel>(context, listen: false);
                var region =
                    Provider.of<ClipRegionModel>(context, listen: false);
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
                  video.player.stop();
                  ffmpeg.export(video.path!, region.start, region.end,
                      video.duration, size, res);
                }
              },
            ),
          )
        ])));
  }
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  XFile? _file;
  bool _dragging = false;

  Offset? offset;

  Widget dropOrVideo(BuildContext context, VideoModel video) {
    var drop = DropTarget(
        onDragDone: (details) async {
          if (details.files.isEmpty) return;
          _file = details.files.first;

          video.open(File(details.files.first.path));
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
            player: video.player,
            showControls: false,
          )
        ],
      );
    }
  }

  @override
  void initState() {
    super.initState();
    var video = Provider.of<VideoModel>(context, listen: false);
    video.player.setVolume(0.5);
  }

  @override
  Widget build(BuildContext context) {
    var video = Provider.of<VideoModel>(context, listen: false);
    return Column(
      children: [
        Expanded(flex: 2, child: dropOrVideo(context, video)),
        Controls(
          onVolume: (volume) {
            video.player.setVolume(volume);
          },
        ),
        Timeline(
          externTime: video.completion,
          onScrub: (time) {},
        ),
      ],
    );
  }
}
