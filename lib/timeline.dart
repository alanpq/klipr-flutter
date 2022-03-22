import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:klipr/models/clip_region.dart';
import 'package:provider/provider.dart';

import 'models/video.dart';

class Timeline extends StatefulWidget {
  final OnScrubFunc? onScrub;
  final OnChangeRegionFunc? onChangeRegion;

  final double externTime;

  const Timeline(
      {Key? key, required this.externTime, this.onScrub, this.onChangeRegion})
      : super(key: key);

  @override
  _TimelineState createState() => _TimelineState();
}

const _height = 50.0;

typedef OnScrubFunc = void Function(double time);
typedef OnChangeRegionFunc = void Function(double start, double end);

class _TimelineState extends State<Timeline> {
  var curPos = 0.0;
  var curPosOffset = 0.0;

  bool _playAnyway = false;

  final _timelineKey = GlobalKey();

  void onScrub(double time, VideoModel video, ClipRegionModel region) {
    video.seekPercentage(time);
    if (!video.player.playback.isPlaying) {
      video.play();
    }

    if (video.completion > region.end) {
      _playAnyway = true;
    } else {
      _playAnyway = false;
    }

    if (widget.onScrub != null) {
      widget.onScrub!(time);
    }
  }

  void _mouseUpdate(PointerEvent e, VideoModel video, ClipRegionModel region) {
    setState(() {
      var w = _timelineKey.currentContext!.size!.width;
      curPos = (e.localPosition.dx / (w - 10)).clamp(0, 1);
      curPosOffset = curPos * (w - 50);
      // curPosOffset -= 5;
    });
    onScrub(curPos, video, region);
  }

  @override
  void initState() {
    super.initState();
    curPos = widget.externTime;

    var video = Provider.of<VideoModel>(context, listen: false);
    var region = Provider.of<ClipRegionModel>(context, listen: false);
    video.player.positionStream.listen((PositionState state) {
      if (video.completion >= region.end && !_playAnyway) {
        video.seekPercentage(region.end);
        video.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var video = context.watch<VideoModel>();
    var region = context.watch<ClipRegionModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: SizedBox(
        height: _height,
        child: MouseRegion(
            key: _timelineKey,
            cursor: SystemMouseCursors.click,
            child: Listener(
              onPointerDown: (e) => {_mouseUpdate(e, video, region)},
              onPointerUp: (e) => {_mouseUpdate(e, video, region)},
              onPointerMove: (e) => {_mouseUpdate(e, video, region)},
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      height: _height,
                      decoration: const BoxDecoration(
                        color: Color(0x2F000000),
                      ),
                    ),
                  ),
                  _ClipRegion(
                      timelineKey: _timelineKey,
                      onChangeRegion: (start, end) {
                        region.setRegion(start, end);
                        if (widget.onChangeRegion != null) {
                          widget.onChangeRegion!(start, end);
                        }
                      },
                      onScrub: (time) {
                        onScrub(time, video, region);
                      }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: FractionallySizedBox(
                      widthFactor: video.completion.clamp(0, 1),
                      child: Align(
                          heightFactor: 1,
                          alignment: Alignment.topRight,
                          child: ticker),
                    ),
                  ),
                  // Text("${video.completion} (${region.start} - ${region.end}"),
                ],
              ),
            )),
      ),
    );
  }
}

Widget ticker = IgnorePointer(
    child: Transform.translate(
        offset: const Offset(-1, 0),
        child: Container(
            width: 2,
            height: _height,
            decoration: const BoxDecoration(color: Colors.white))));

const green = Color(0xFF3AD6F1);
const radius = Radius.circular(5);

class _ClipRegion extends StatefulWidget {
  final OnChangeRegionFunc? onChangeRegion;
  final OnScrubFunc? onScrub;

  final GlobalKey timelineKey;

  const _ClipRegion(
      {Key? key, required this.timelineKey, this.onChangeRegion, this.onScrub})
      : super(key: key);

  @override
  _ClipRegionState createState() => _ClipRegionState();
}

class _ClipRegionState extends State<_ClipRegion> {
  var _held = "";

  var _left = 0.0;
  var _right = double.infinity;

  var _start = 0.0;
  var _end = 1.0;

  void _pointerUp(e) {
    _held = "";
  }

  double _move(PointerMoveEvent e, double value) {
    return (value + e.delta.dx);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (e) {
        if (_held == "") return;
        var w = widget.timelineKey.currentContext!.size!.width;
        switch (_held) {
          case "start":
            setState(() {
              _left = _move(e, _left);
              if (_left + 10 > _right) {
                _right = _left + 10;
                _end = (_right / w).clamp(0, 1);
              }
              _start = (_left / w).clamp(0, 1);

              _left = _start * w;
              _right = _end * w;
            });
            if (widget.onChangeRegion != null) {
              widget.onChangeRegion!(_start, _end);
            }
            if (widget.onScrub != null) {
              widget.onScrub!(_start);
            }
            break;
          case "end":
            setState(() {
              _right = _move(e, _right);
              if (_right - 10 < _left) {
                _left = (_right - 10).clamp(0, w);
                _right = _left + 10;
                _start = (_left / w).clamp(0, 1);
              }
              _end = (_right / w).clamp(0, 1);

              _left = _start * w;
              _right = _end * w;
            });
            if (widget.onChangeRegion != null) {
              widget.onChangeRegion!(_start, _end);
            }
            if (widget.onScrub != null) {
              widget.onScrub!(_end);
            }
            break;
        }
      },
      child: Padding(
        padding: EdgeInsets.only(left: _left),
        child: SizedBox(
          width: _right - _left,
          child: Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Listener(
                  onPointerDown: (e) {
                    _held = "start";
                  },
                  onPointerUp: _pointerUp,
                  child: dragger(context, false),
                ),
              ),
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Listener(
                    onPointerDown: (e) {
                      _held = "time";
                    },
                    onPointerUp: _pointerUp,
                    child: Container(
                      height: _height,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5A6481),
                        border: Border.symmetric(
                            horizontal: BorderSide(color: green)),
                      ),
                    ),
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Listener(
                  onPointerDown: (e) {
                    _held = "end";
                  },
                  onPointerUp: (e) {
                    _held = "";
                  },
                  child: dragger(context, true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget dragger(BuildContext context, bool isRight) {
  var border = !isRight
      ? const BorderRadius.only(topLeft: radius, bottomLeft: radius)
      : const BorderRadius.only(topRight: radius, bottomRight: radius);
  return Container(
      height: _height,
      width: 5,
      decoration: BoxDecoration(
        color: green,
        borderRadius: border,
      ));
}
