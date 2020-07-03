import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'html_model.dart';

class MetaModel extends ChangeNotifier {
  final SharedPreferences prefs;
  final _savePosition = PublishSubject<Function>();

  MetaModel(
    this.prefs,
  ) {
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
}
