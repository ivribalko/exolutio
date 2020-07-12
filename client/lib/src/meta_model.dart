import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared/html_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MetaModel extends ChangeNotifier {
  static const fontKey = 'font';
  static const fontSizeKey = 'fontSize';
  final SharedPreferences prefs;
  final _fonts = ['Merriweather_Sans', 'Literata'];
  final _fontSizes = [17.0, 20.0, 24.0];

  MetaModel(
    this.prefs,
  ) {
    _font = prefs.getString(fontKey) ?? _fonts[0];
    _fontSize = prefs.getDouble(fontSizeKey) ?? _fontSizes[0];
  }

  double getProgress(LinkData link) {
    if (prefs.containsKey(link.url)) {
      final save = _loadSave(link);
      return save.currentPosition / save.maximumPosition;
    } else {
      return null;
    }
  }

  double getPosition(LinkData link) {
    if (prefs.containsKey(link.url)) {
      return _loadSave(link).currentPosition;
    } else {
      return null;
    }
  }

  void savePosition(LinkData link, double at, double max) {
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
  }

  String _font;
  String get font => _font;
  void nextFont() {
    final index = (_fonts.indexOf(_font) + 1) % _fonts.length;
    prefs.setString(fontKey, _font = _fonts[index]);
    notifyListeners();
  }

  double _fontSize;
  double get fontSize => _fontSize;
  void nextFontSize() {
    // some font sizes misplace links, can't use font scale
    final index = (_fontSizes.indexOf(_fontSize) + 1) % _fontSizes.length;
    prefs.setDouble(fontSizeKey, _fontSize = _fontSizes[index]);
    notifyListeners();
  }

  _Save _loadSave(LinkData link) {
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
