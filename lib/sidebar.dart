import 'package:flutter/material.dart';
import 'package:klipr/export.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: const [Export()]);
  }
}
