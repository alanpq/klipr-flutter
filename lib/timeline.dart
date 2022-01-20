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
        padding: const EdgeInsets.symmetric(horizontal: 10),
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

Widget ticker = Container(
    width: 2,
    height: _height,
    decoration: const BoxDecoration(color: Colors.white));

const green = Color(0xFF3AF13A);
const radius = Radius.circular(5);

class _ClipRegion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: _height,
          decoration: const BoxDecoration(
            color: Color(0xFF5A6481),
            border: Border.symmetric(horizontal: BorderSide(color: green)),
            // borderRadius: BorderRadius.all(radius),
          ),
        ),
        dragger(context, false),
        dragger(context, true),
      ],
    );
  }
}

Widget dragger(BuildContext context, bool isRight) {
  var border = !isRight
      ? const BorderRadius.only(topLeft: radius, bottomLeft: radius)
      : const BorderRadius.only(topRight: radius, bottomRight: radius);
  return Align(
      alignment: isRight ? Alignment.topRight : Alignment.topLeft,
      child: Transform.translate(
          offset: Offset(5 * (isRight ? 1 : -1), 0),
          child: Container(
              height: _height,
              width: 5,
              decoration: BoxDecoration(
                color: green,
                borderRadius: border,
              ))));
}
