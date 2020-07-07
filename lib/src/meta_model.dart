import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'html_model.dart';

class MetaModel extends ChangeNotifier {
  static const fontSizeKey = 'fontSize';
  final SharedPreferences prefs;
  final _savePosition = PublishSubject<Function>();
  final _fontSizes = [17.0, 20.0, 24.0];

  MetaModel(
    this.prefs,
  ) {
    _fontSize = prefs.getDouble(fontSizeKey) ?? _fontSizes[0];
    _savePosition
        .throttle(
          (event) => TimerStream(
            true,
            Duration(milliseconds: 500),
          ),
          trailing: true,
        )
        .listen((value) => value());
  }

  double getProgress(Link link) {
    if (prefs.containsKey(link.url)) {
      return prefs.getDouble(link.url);
    } else {
      return null;
    }
  }

  double getPosition(Link link) {
    if (prefs.containsKey(link.url)) {
      return prefs.getDouble(link.url);
    } else {
      return null;
    }
  }

  void savePosition(Link link, double position, double max) {
    _savePosition.add(() {
      prefs.setDouble(link.url, position);
      notifyListeners();
    });
  }

  double _fontSize;
  double get fontSize => _fontSize;
  void nextFontSize() {
    // some font sizes misplace links, can't use font scale
    final index = (_fontSizes.indexOf(_fontSize) + 1) % _fontSizes.length;
    prefs.setDouble(fontSizeKey, _fontSize = _fontSizes[index]);
    notifyListeners();
  }
}
