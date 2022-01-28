import 'dart:async';
import 'dart:convert';

import 'dart:io';

import 'dart:typed_data';

/// Basic line streaming. Assuming system encoding
Stream<String> streamLines(Stream<List<int>> stream,
    {Encoding encoding = systemEncoding}) {
  StreamSubscription? subscription;
  List<int>? currentLine;
  const endOfLine = 10;
  const lineFeed = 13;
  late StreamController<String> ctlr;
  ctlr = StreamController<String>(onListen: () {
    void addCurrentLine() {
      if (currentLine?.isNotEmpty ?? false) {
        try {
          ctlr.add(systemEncoding.decode(currentLine!));
        } catch (_) {
          // Ignore nad encoded line
          // print('ignoring: $currentLine');
        }
      }
      currentLine = null;
    }

    void addToCurrentLine(List<int> data) {
      if (currentLine == null) {
        currentLine = data;
      } else {
        var newCurrentLine = Uint8List(currentLine!.length + data.length);
        newCurrentLine.setAll(0, currentLine!);
        newCurrentLine.setAll(currentLine!.length, data);
        currentLine = newCurrentLine;
      }
    }

    subscription = stream.listen((data) {
      // var _w;
      // print('read $data');
      // devPrint('read $data');
      // look for \n (10)
      var start = 0;
      for (var i = 0; i < data.length; i++) {
        var byte = data[i];
        if (byte == endOfLine || byte == lineFeed) {
          addToCurrentLine(data.sublist(start, i));
          addCurrentLine();
          // Skip it
          start = i + 1;
        }
      }
      // Store last current line
      if (data.length > start) {
        addToCurrentLine(data.sublist(start, data.length));
      }
    }, onDone: () {
      // Last one
      if (currentLine != null) {
        addCurrentLine();
      }
      ctlr.close();
    });
  }, onCancel: () {
    subscription?.cancel();
  });

  return ctlr.stream;
}
