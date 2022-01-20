import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:math';

class Timeline extends StatefulWidget {
  const Timeline({Key? key}) : super(key: key);

  @override
  _TimelineState createState() => _TimelineState();
}

const _height = 50.0;

class _TimelineState extends State<Timeline> {
  var curPos = 0.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: SizedBox(
          height: 100,
          child: Stack(
            children: [
              Container(
                height: _height,
                decoration: const BoxDecoration(
                  color: Color(0xFF2B2B2C),
                ),
              ),
              _ClipRegion(),
              Transform.translate(
                offset: Offset(curPos, 0),
                child: ticker,
              ),
            ],
          ),
        ));
  }
}

Widget ticker = IgnorePointer(
    child: Transform.translate(
        offset: const Offset(5, 0),
        child: Container(
            width: 2,
            height: _height,
            decoration: const BoxDecoration(color: Colors.white))));

const green = Color(0xFF3AF13A);
const radius = Radius.circular(5);

class _ClipRegion extends StatefulWidget {
  @override
  _ClipRegionState createState() => _ClipRegionState();
}

class _ClipRegionState extends State<_ClipRegion> {
  var held = "";

  var left = 0.0;
  var right = 30.0;

  var start = 0.0;
  var end = 1.0;

  void _pointerUp(e) {
    held = "";
  }

  double _move(PointerMoveEvent e, double value) {
    return (value + e.delta.dx);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (e) {
        if (held == "") return;
        switch (held) {
          case "start":
            setState(() {
              left = _move(e, left);
              if (left + 10 > right) {
                right = left + 10;
                end = (right / window.physicalSize.width).clamp(0, 1);
              }
              start = (left / window.physicalSize.width).clamp(0, 1);

              left = start * window.physicalSize.width;
              right = end * window.physicalSize.width;
            });
            break;
          case "end":
            setState(() {
              right = _move(e, right);
              if (right - 10 < left) {
                left = right - 10;
                end = (right / window.physicalSize.width).clamp(0, 1);
              }
              end = (right / window.physicalSize.width).clamp(0, 1);

              left = start * window.physicalSize.width;
              right = end * window.physicalSize.width;
            });
            break;
        }
      },
      child: Padding(
        padding: EdgeInsets.only(left: left),
        child: SizedBox(
          width: right - left,
          child: Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Listener(
                  onPointerDown: (e) {
                    held = "start";
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
                      held = "time";
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
                    held = "end";
                  },
                  onPointerUp: (e) {
                    held = "";
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
