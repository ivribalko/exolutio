import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'html_model.dart';

class MetaModel extends ChangeNotifier {
  static const fontSizeKey = 'fontScale';
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

  bool isRead(Link link) => prefs.containsKey(link.url);

  double getPosition(Article article) {
    if (prefs.containsKey(article.link.url)) {
      return prefs.getDouble(article.link.url);
    } else {
      return null;
    }
  }

  void savePosition(Article article, double position) {
    _savePosition.add(() {
      if (position <= 0) {
        prefs.remove(article.link.url);
      } else {
        prefs.setDouble(article.link.url, position);
      }
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
