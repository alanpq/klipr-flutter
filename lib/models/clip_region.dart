import 'package:flutter/foundation.dart';

class ClipRegionModel extends ChangeNotifier {
  double _start = 0.0;
  double _end = 1.0;

  double get start => _start;
  double get end => _end;

  void setRegion(double start, double end) {
    _start = start;
    _end = end;
    notifyListeners();
  }

  void setStart(double start) {
    setRegion(start, end);
  }

  void setEnd(double end) {
    setRegion(start, end);
  }
}
