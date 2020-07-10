import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared/html_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final save = _loadSave(link);
      return save.currentPosition / save.maximumPosition;
    } else {
      return null;
    }
  }

  double getPosition(Link link) {
    if (prefs.containsKey(link.url)) {
      return _loadSave(link).currentPosition;
    } else {
      return null;
    }
  }

  void savePosition(Link link, double at, double max) {
    _savePosition.add(() {
      prefs.setString(
        link.url,
        jsonEncode(
          _Save(
            currentPosition: at,
            maximumPosition: max,
          ).toJson(),
        ),
      );
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

  _Save _loadSave(Link link) {
    return _Save.fromJson(jsonDecode(prefs.getString(link.url)));
  }
}

class _Save {
  double _currentPosition;
  double _maximumPosition;

  double get currentPosition => _currentPosition;
  double get maximumPosition => _maximumPosition;

  _Save({double currentPosition, double maximumPosition}) {
    _currentPosition = currentPosition;
    _maximumPosition = maximumPosition;
  }

  _Save.fromJson(dynamic json) {
    _currentPosition = json["currentPosition"];
    _maximumPosition = json["maximumPosition"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["currentPosition"] = _currentPosition;
    map["maximumPosition"] = _maximumPosition;
    return map;
  }
}
