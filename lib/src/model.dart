import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _Root = 'https://evo-lutio.livejournal.com/';

const List<String> _Contents = [
  'div.b-singlepost-bodywrapper',
  'div.aentry-post__text.aentry-post__text--view',
];

class Model extends ChangeNotifier {
  Model(this.prefs) {
    _read = prefs.getStringList(_readKey)?.toSet() ?? <String>[].toSet();
  }

  static const String _readKey = 'articlesRead';

  final SharedPreferences prefs;
  Set<String> _read;
  Set<String> get read => _read;

  Future<List<Link>> get links => Client()
      .get(_Root)
      .then((value) => parse(value.body))
      .then((value) => value.querySelectorAll('dt.entry-title'))
      .then((value) => value
          .where((element) => element.text.contains('Письмо'))
          .map((e) => e.children.first)
          .map((e) => Link(
                e.attributes['href'],
                e.text,
              ))
          .toList());

  Future<Article> article(Link link) => Client()
      .get(link.url)
      .then((value) => parse(value.body))
      .then((value) => Article(
            link.title,
            _getArticleText(value),
            '${link.url}#comments',
          ));

  bool isRead(Link link) => _read.contains(link.url);

  void setRead(Link link) {
    _read.add(link.url);
    prefs.setStringList(_readKey, _read.toList());
    notifyListeners();
  }

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
  Article(this.title, this.text, this.commentsUrl);

  final String title;
  final String text;
  final String commentsUrl;
}
