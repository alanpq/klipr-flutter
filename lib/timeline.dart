import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:math';

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

  final _timelineKey = GlobalKey();

  void _mouseUpdate(PointerEvent e) {
    setState(() {
      var w = _timelineKey.currentContext!.size!.width;
      curPos = (e.localPosition.dx / (w - 10)).clamp(0, 1);
      curPosOffset = curPos * (w - 50);
      // curPosOffset -= 5;
    });
    if (widget.onScrub != null) {
      widget.onScrub!(curPos);
    }
  }

  @override
  void initState() {
    super.initState();
    curPos = widget.externTime;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: SizedBox(
        height: _height,
        child: MouseRegion(
            key: _timelineKey,
            cursor: SystemMouseCursors.click,
            child: Listener(
              onPointerDown: _mouseUpdate,
              onPointerUp: _mouseUpdate,
              onPointerMove: _mouseUpdate,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      height: _height,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2929FF),
                      ),
                    ),
                  ),
                  _ClipRegion(
                      timelineKey: _timelineKey,
                      onChangeRegion: (start, end) {
                        if (widget.onChangeRegion != null) {
                          widget.onChangeRegion!(start, end);
                        }
                      },
                      onScrub: (time) {
                        // setState(() {
                        //   curPos = time;
                        //   curPosOffset =
                        //       curPos * _timelineKey.currentContext!.size!.width - 5;
                        // });
                        if (widget.onScrub != null) {
                          widget.onScrub!(time);
                        }
                      }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: FractionallySizedBox(
                      widthFactor: widget.externTime.clamp(0, 1),
                      child: Align(
                          heightFactor: 1,
                          alignment: Alignment.topRight,
                          child: ticker),
                    ),
                  ),
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

const green = Color(0xFF3AF13A);
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
  var _right = 30.0;

  var _start = 0.0;
  var _end = 0.5;

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
