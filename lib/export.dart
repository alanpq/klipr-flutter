import 'package:flutter/material.dart';

class Export extends StatefulWidget {
  const Export({Key? key}) : super(key: key);

  @override
  State<Export> createState() => _ExportState();
}

class _ExportState extends State<Export> {
  double _size = 8;
  double _other = 0;

  final GlobalKey _inputKey = GlobalKey();

  void _onChanged(double? value) {
    if (value == null) return;
    setState(() {
      _size = value;
    });
  }

  Widget sizeTile(double size) {
    return RadioListTile<double>(
      title: Text(size.toStringAsFixed(0) + " MB"),
      value: size,
      groupValue: _size,
      onChanged: _onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      sizeTile(8),
      sizeTile(50),
      sizeTile(100),
      InkWell(
        onTap: () {
          if (-1 != _size) {
            _onChanged(-1);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            children: <Widget>[
              Radio<double>(
                groupValue: _size,
                value: -1,
                onChanged: _onChanged,
              ),
              Expanded(
                  child: TextField(
                key: _inputKey,
                enabled: _size == -1,
                onTap: () => _onChanged(-1),
                decoration: const InputDecoration(hintText: "Enter size (MB)"),
              )),
            ],
          ),
        ),
      )
    ]);
  }
}
