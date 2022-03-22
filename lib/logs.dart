import 'package:flutter/material.dart';
import 'package:klipr/export.dart';
import 'package:klipr/models/ffmpeg.dart';
import 'package:provider/provider.dart';

const lineStyles = [TextStyle(backgroundColor: Color(0x59FFFFFF)), TextStyle()];

const lineStyle = TextStyle(color: Color(0x81FFFFFF));

class Logs extends StatelessWidget {
  const Logs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var ffmpeg = Provider.of<FFmpeg>(context, listen: true);
    List<TextSpan> lines = [];
    for (var i = ffmpeg.error.length - 1; i >= 0; i--) {
      var l = ffmpeg.error[i];
      lines.add(TextSpan(text: l + "\n", style: lineStyle));
    }
    return Flexible(
        child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
      children: [
        SelectableText.rich(
          TextSpan(children: lines),
          textWidthBasis: TextWidthBasis.parent,
        ),
      ],
    ));
  }
}
