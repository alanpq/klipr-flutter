import 'dart:io';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:dart_vlc/dart_vlc.dart';

class VideoModel extends ChangeNotifier {
  final Player _player = Player(id: 1234);
  Player get player => _player;

  File? _file;

  double position = 0;
  double duration = 0; // microseconds / 1000000

  double completion = 0;

  String? get path => _file?.path;

  VideoModel() {
    _player.positionStream.listen((PositionState state) {
      position = state.position!.inMicroseconds / 1000000;
      duration = state.duration!.inMicroseconds / 1000000;
      completion = position / duration;
      notifyListeners();
    });
  }

  void seek(double seconds) {
    position = seconds;
    completion = position / duration;
    notifyListeners();
    _player.seek(Duration(microseconds: (seconds * 1000000).round()));
  }

  void seekPercentage(double percent) {
    seek(percent * duration);
  }

  void open(File file) {
    _file = file;
    _player.open(Media.file(file));
  }

  void play() {
    _player.play();
  }

  void pause() {
    _player.pause();
  }

  void playOrPause() {
    _player.playOrPause();
  }
}
