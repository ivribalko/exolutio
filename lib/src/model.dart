import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _Root = 'https://evo-lutio.livejournal.com/';

const List<String> _Contents = [
  'div.b-singlepost-bodywrapper',
  'div.aentry-post__text.aentry-post__text--view',
];

enum Tag {
  letters,
  others,
}

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
  final _articlesCache = Map<String, Article>();
  final _savePosition = PublishSubject<Function>();
  final _pagesCache = <List<dom.Element>>[];

  List<Link> operator [](Tag tag) {
    switch (tag) {
      case Tag.letters:
        return _articles(_isLetter);
      case Tag.others:
        return _articles(_isNotLetter);
      default:
        throw UnimplementedError();
    }
  }

  Future<List<dom.Element>> _page(int index) {
    if (_pagesCache.length > index) {
      return Future.value(_pagesCache[index]);
    } else {
      return _loadPage(index).then((e) {
        _pagesCache.add(e);
        return e;
      });
    }
  }

  Future<List<dom.Element>> _loadPage(int index) => Client()
      .get(_Root + '?skip=${index * 50}')
      .then((value) => parse(value.body))
      .then((value) => value.querySelectorAll('dt.entry-title'));

  FutureOr<Article> article(Link link) =>
      _articlesCache[link.url] ??
      Client()
          .get(link.url)
          .then((value) => parse(value.body))
          .then((value) => Article(
                link.url,
                link.title,
                _getArticleText(value),
                '${link.url}#comments',
              ))
          .then((value) => _articlesCache[link.url] = value);

  bool get any => _pagesCache.isNotEmpty;

  void loadMore() {
    _page(_pagesCache.length).then((value) => notifyListeners());
  }

  void refresh() {
    _articlesCache.clear();
    _pagesCache.clear();
    loadMore();
  }

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

  List<Link> _articles(bool test(element)) => _pagesCache.isEmpty
      ? []
      : _pagesCache
          .reduce((value, element) {
            value.addAll(element);
            return value;
          })
          .where(test)
          .map((e) => e.children.first)
          .where((element) => element.text.isNotEmpty)
          .map((e) => Link(
                e.attributes['href'],
                e.text,
              ))
          .toList();

  String _getArticleText(dom.Document value) {
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
