import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Controls extends StatefulWidget {
  const Controls({Key? key, required this.onVolume}) : super(key: key);

  final void Function(double volume) onVolume;

  @override
  State<Controls> createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  var _volume = 0.5;
  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _volume,
      onChanged: (value) {
        setState(() {
          _volume = value;
        });
        widget.onVolume(value);
      },
      min: 0,
      max: 1,
    );
  }
}
