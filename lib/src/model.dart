import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _Root = 'https://evo-lutio.livejournal.com/';

const List<String> _Contents = [
  'div.b-singlepost-bodywrapper',
  'div.aentry-post__text.aentry-post__text--view',
];

class Model extends ChangeNotifier {
  Model(this.prefs) {
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

  final SharedPreferences prefs;
  final _cache = Map<String, Article>();
  final _savePosition = PublishSubject<Function>();
  final _firstPage = Client()
      .get(_Root)
      .then((value) => parse(value.body))
      .then((value) => value.querySelectorAll('dt.entry-title'));

  bool _mail = true;
  bool get mail => _mail;
  set mail(bool on) {
    if (_mail != on) {
      _mail = on;
      notifyListeners();
    }
  }

  Future<List<Link>> get letters => _articles(_isLetter);

  Future<List<Link>> get others => _articles(_isNotLetter);

  FutureOr<Article> article(Link link) =>
      _cache[link.url] ??
      Client()
          .get(link.url)
          .then((value) => parse(value.body))
          .then((value) => Article(
                link.url,
                link.title,
                _getArticleText(value),
                '${link.url}#comments',
              ))
          .then((value) => _cache[link.url] = value);

  bool isRead(Link link) => prefs.containsKey(link.url);

  double getPosition(Article article) {
    if (prefs.containsKey(article.url)) {
      return prefs.getDouble(article.url);
    } else {
      return 0.0;
    }
  }

  void savePosition(Article article, double position) {
    _savePosition.add(() {
      if (position <= 0) {
        prefs.remove(article.url);
      } else {
        prefs.setDouble(article.url, position);
      }
      notifyListeners();
    });
  }

  bool _isNotLetter(e) => !_isLetter(e);
  bool _isLetter(e) => e.text.contains('Письмо:');

  Future<List<Link>> _articles(bool test(element)) =>
      _firstPage.then((value) => value
          .where(test)
          .map((e) => e.children.first)
          .where((element) => element.text.isNotEmpty)
          .map((e) => Link(
                e.attributes['href'],
                e.text,
              ))
          .toList());

  String _getArticleText(Document value) {
    return _Contents.map(value.querySelector)
        .firstWhere((element) => element?.text?.isNotEmpty ?? false)
        .innerHtml;
  }
}

class Link {
  Link(this.url, this.title);

  final String url;
  final String title;
}

class Article {
  Article(this.url, this.title, this.text, this.commentsUrl);

  final String url;
  final String title;
  final String text;
  final String commentsUrl;
}
