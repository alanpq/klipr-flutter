import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:klipr/sidebar.dart';
import 'package:klipr/timeline.dart';

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

class Main extends StatelessWidget {
  const Main({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Expanded(flex: 2, child: Text('video')),
        Expanded(flex: 1, child: Timeline())
      ],
    );
  }
}

class _Video extends StatefulWidget {
  @override
  _VideoState createState() => _VideoState();
}

class _VideoState extends State<_Video> {
  Player _player = Player(id: 1234);
  Media _media = Media.asset('assets/test.mp4');

  @override
  void initState() {
    super.initState();
    if (this.mounted) {
      this._player.open(_media);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      player: _player,
      width: 500,
      height: 500,
    );
  }
}
