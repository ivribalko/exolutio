import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'html_model.dart';

class MetaModel extends ChangeNotifier {
  static const fontScaleKey = 'fontScale';
  final SharedPreferences prefs;
  final _savePosition = PublishSubject<Function>();
  final _fontScales = [1.0, 1.5, 2.0];

  MetaModel(
    this.prefs,
  ) {
    _fontScale = prefs.getDouble(fontScaleKey) ?? 1;
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

  double _fontScale;
  double get fontScale => _fontScale;
  void nextScale() {
    final index = (_fontScales.indexOf(_fontScale) + 1) % _fontScales.length;
    prefs.setDouble(fontScaleKey, _fontScale = _fontScales[index]);
    notifyListeners();
  }
}
