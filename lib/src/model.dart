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

class ArticleModel extends ChangeNotifier {
  ArticleModel(this.prefs) {
    _read = prefs.getStringList(_readKey)?.toSet() ?? <String>[].toSet();
  }

  static const String _readKey = 'articlesRead';

  final SharedPreferences prefs;
  Set<String> _read;

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
                _read.contains(e.attributes['href']),
              ))
          .toList());

  Future<Article> article(Link link) => Client()
      .get(link.url)
      .then((value) => parse(value.body))
      .then((value) => Article(
            link.title,
            _getArticleText(value),
            'COMMENTS NOT IMPLEMENTED',
          ));

  void setRead(Link link) {
    _read.add(link.url);
    prefs.setStringList(_readKey, _read.toList());
    notifyListeners();
  }

  String _getArticleText(Document value) {
    return _Contents.map(value.querySelector)
        .firstWhere((element) => element?.text?.isNotEmpty ?? false)
        .text;
  }
}

class Link {
  Link(this.url, this.title, this.read);

  final String url;
  final String title;
  final bool read;
}

class Article {
  Article(this.title, this.text, this.comments);

  final String title;
  final String text;
  final String comments;
}
