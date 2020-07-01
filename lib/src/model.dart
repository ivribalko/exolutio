import 'dart:async';
import 'dart:convert';

import 'package:exolutio/src/comment.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'loader.dart';

enum Tag {
  letters,
  others,
}

const String CommentLink = "comment:";
const _startQuotes = '<«"\'‘“';
const _ceaseQuotes = '>»"\'’”';
const _word = '\\S+?';
const _any = '.*?';
const _ws = '\\s+?';

class Model extends ChangeNotifier {
  Model(
    this.loader,
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

  final Loader loader;
  final SharedPreferences prefs;
  final _articlePageCache = <List<dom.Element>>[];
  final _articleCache = Map<String, Article>();
  final _savePosition = PublishSubject<Function>();
  final _quotesRegExp = RegExp(
    '[$_startQuotes]($_any$_word$_ws$_word$_any)[$_ceaseQuotes]',
    caseSensitive: false,
  );

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
    if (_articlePageCache.length > index) {
      return Future.value(_articlePageCache[index]);
    } else {
      return _loadPage(index).then(_cachePage);
    }
  }

  Future<List<dom.Element>> _loadPage(int index) => loader
      .page(index)
      .then(parse)
      .then((value) => value.querySelectorAll('dt.entry-title'));

  List<dom.Element> _cachePage(List<dom.Element> e) {
    _articlePageCache.add(e);
    return e;
  }

  FutureOr<Article> article(Link link) =>
      _articleCache[link.url] ??
      _fetchArticle(link.url)
          .then((value) => _getArticle(link, value))
          .then((value) => _articleCache[link.url] = value);

  Future<dom.Document> _fetchArticle(String url) {
    return loader.body(url).then(parse);
  }

  bool get any => _articlePageCache.isNotEmpty;

  void loadMore() {
    _page(_articlePageCache.length).then((value) => notifyListeners());
  }

  void refresh() {
    _articleCache.clear();
    _articlePageCache.clear();
    loadMore();
  }

  bool isRead(Link link) => prefs.containsKey(link.url);

  double getPosition(Article article) {
    if (prefs.containsKey(article.url)) {
      return prefs.getDouble(article.url);
    } else {
      return null;
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

  List<Link> _articles(bool test(element)) => _articlePageCache.isEmpty
      ? []
      : _articlePageCache
          .reduce((value, element) => value..addAll(element))
          .where(test)
          .map((e) => e.children.first)
          .where((element) => element.text.isNotEmpty)
          .map((e) => Link(
                e.attributes['href'],
                e.text,
              ))
          .toList();

  Future<Article> _getArticle(Link link, dom.Document value) async {
    final comments = await _getUndynamicComments(link, value);
    final article = _colored(value, comments);
    return Article(
      link.url,
      link.title,
      article,
      comments,
    );
  }

  String _colored(dom.Document value, List<Comment> comments) {
    var article = value.querySelector('article.b-singlepost-body').outerHtml;

    var sorted = comments
        .map((e) => MapEntry(comments.indexOf(e), _quotes(e, article)))
        .toDescendingLength();

    for (final entry in sorted) {
      final index = entry.key;
      final quote = entry.value;
      final clean = quote.clean().clean(); // two times!

      if (article.indexOf(clean) > -1) {
        final link = '$CommentLink$index';
        final href = ' [ <a class="quote" href=$link>ответ</a> ]';
        final span = '<span class="quote">';
        final color = _colorize(comments[index], clean, '$span$clean</span>');

        article = article.replaceFirst(clean, '$span$clean$href</span>');

        comments.removeAt(index);
        comments.insert(index, color);
      }
    }

    return article;
  }

  Iterable<String> _quotes(Comment comment, String article) {
    return _quotesRegExp
        .allMatches(parse(comment.article).body.text)
        .map((e) => e[0]);
  }

  Comment _colorize(Comment comment, String from, String span) {
    final article = comment.article.replaceFirst(from, span);
    assert(article != comment.article);
    return Comment.map(comment.toMap()..['article'] = article);
  }

  // if where() directly in _getComments it doesn't work TODO
  Future<List<Comment>> _getUndynamicComments(
    Link link,
    dom.Document firstPage,
  ) async {
    final commentsPagesCount = firstPage
            .querySelector(
                '#comments > div.b-xylem.b-xylem-nocomment.b-xylem-first > div > ul')
            ?.children
            ?.length ??
        1;

    final other = await Future.wait(
        List<int>.generate(commentsPagesCount - 1, (index) => index + 2)
            .map((e) => '${link.url}?page=$e')
            .map(_fetchArticle));

    final comments = List<Comment>();

    for (final page in [firstPage, ...other]) {
      comments.addAll(_getComments(page));
    }

    final descending = expandable(comments).toList();

    descending.sort((a, b) => b.key.compareTo(a.key));

    // 1 topic starter + 1 first answer
    const int dupes = 2;

    final fetched = await Future.wait(descending
        .map((e) => e.value)
        .map(_fetchArticle)
        .map((e) => e
            .then(_getComments)
            .then((value) => value..removeRange(0, dupes))));

    int realIndex(int fetchIndex) => descending[fetchIndex].key + dupes;

    fetched
        .asMap()
        .forEach((key, value) => comments.insertAll(realIndex(key), value));

    return comments;
  }

  @visibleForTesting
  Iterable<MapEntry<int, String>> expandable(List<Comment> comments) {
    return comments
        .where((e) => e.level == 1)
        .map((e) => MapEntry(
              comments.indexOf(e),
              e.actions
                  ?.firstWhere(
                    (e) => e.name == 'expandchilds',
                    orElse: () => null,
                  )
                  ?.href,
            ))
        .where((e) => e?.value?.isNotEmpty ?? false);
  }

  List<Comment> _getComments(dom.Document value) {
    const commentsSource = 'Site.page = ';
    final script = value.body
        .querySelectorAll('script')
        .firstWhere((e) => e.innerHtml.contains(commentsSource))
        .nodes
        .first
        .text;

    final start = script.indexOf(commentsSource) + 'Site.page = '.length;
    final temp = script.substring(start, script.length - 1);
    final end = temp.indexOf('Site.');

    final json = temp.substring(0, end).trim().replaceAll(';', '');
    final user = jsonDecode(json);

    return user['comments']
        .map((e) => Comment.map(e))
        .cast<Comment>()
        .where((e) => (e as Comment).article?.isNotEmpty ?? false)
        .toList();
  }
}

class Link {
  Link(this.url, this.title);

  final String url;
  final String title;
}

class Article {
  Article(
    this.url,
    this.title,
    this.text,
    this.comments,
  );

  final String url;
  final String title;
  final String text;
  final List<Comment> comments;
}

extension _Madness on Iterable<MapEntry<int, Iterable<String>>> {
  List<MapEntry<int, String>> toDescendingLength() {
    // create a list
    var result = List<MapEntry<int, String>>();

    // SelectMany from all comments with comment index
    this.fold(result, (result, element) {
      element.value.forEach((e) {
        result.add(MapEntry(element.key, e));
      });
      return result;
    });

    // sort lengthy comments to be first
    result.sort((a, b) => b.value.length.compareTo(a.value.length));

    return result;
  }
}

extension _Extension on String {
  static final _extras = _startQuotes.runes
      .followedBy(_ceaseQuotes.runes)
      .map((e) => String.fromCharCode(e))
      .followedBy(['...', '-', '…']).toList();

  String clean() {
    var result = this;

    for (final char in _extras) {
      result = result.trim().unsurround(char);
    }

    return result.trim();
  }

  String unsurround(String remove) {
    var result = this;

    if (result.startsWith(remove)) {
      result = result.substring(remove.length);
    }
    if (result.endsWith(remove)) {
      result = result.substring(0, result.length - remove.length);
    }

    return result;
  }
}
