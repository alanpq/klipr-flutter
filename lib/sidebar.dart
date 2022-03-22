import 'package:flutter/material.dart';
import 'package:klipr/export.dart';
import 'package:klipr/logs.dart';

class Sidebar extends StatelessWidget {
  final void Function(double size) onExport;
  const Sidebar({Key? key, required this.onExport}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Export(
        onExport: onExport,
      ),
      const Logs(),
    ]);
  }
}
