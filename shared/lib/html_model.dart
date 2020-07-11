import 'dart:async';
import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

import 'comment.dart';
import 'loader.dart';

enum Tag {
  any,
  letters,
  others,
}

const String urlKey = 'url';
const String dateKey = 'date';
const String titleKey = 'title';
const String CommentLink = "comment:";
const _startQuotes = '<«"\'‘“';
const _ceaseQuotes = '>»"\'’”';
const _word = '\\S+?';
const _any = '.*?';
const _ws = '\\s+?';

class HtmlModel {
  HtmlModel(
    this.loader,
  );

  final Loader loader;
  final _articlePageCache = <List<dom.Element>>[];
  final _articleCache = Map<String, Article>();
  final _quotesRegExp = RegExp(
    '[$_startQuotes]$_any$_word$_ws$_word$_any[$_ceaseQuotes]',
    caseSensitive: false,
  );

  List<Link> cached(Tag tag) {
    switch (tag) {
      case Tag.any:
        return _articles((_) => true);
      case Tag.letters:
        return _articles(_isLetter);
      case Tag.others:
        return _articles(_isNotLetter);
      default:
        throw UnimplementedError();
    }
  }

  List<Link> operator [](Tag tag) => cached(tag);

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
      .then((value) => value.querySelectorAll('dl.entry.hentry'));

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

  Future<List<Link>> loadMore() async {
    return _page(_articlePageCache.length).then((value) => this[Tag.any]);
  }

  void refresh() {
    _articleCache.clear();
    _articlePageCache.clear();
    loadMore();
  }

  bool _isNotLetter(e) => !_isLetter(e);
  bool _isLetter(e) => e.text.contains('Письмо:');

  List<Link> _articles(bool test(element)) => _articlePageCache.isEmpty
      ? []
      : _articlePageCache
          .fold<List<dom.Element>>([], (v, element) => v..addAll(element))
          .map(_hrefAndDateEntry)
          .where((e) => test(e.key))
          .where((e) => e.key.text.isNotEmpty)
          .where((e) => e.key.text != 'ПРАВИЛА БЛОГА')
          .map((e) => Link.fromHtml(e.key, e.value))
          .toList();

  MapEntry<dom.Element, dom.Element> _hrefAndDateEntry(e) {
    return MapEntry(
      e.querySelector('a'),
      e.querySelector('dd.entry-date > abbr'),
    );
  }

  Future<Article> _getArticle(Link link, dom.Document value) async {
    final comments = await _getUndynamicComments(link, value);
    final article = _colored(value, comments);
    return Article(
      link,
      article,
      comments,
    );
  }

  String _colored(dom.Document value, List<Comment> comments) {
    var article = value.querySelector('article.b-singlepost-body').outerHtml;

    var sorted = comments
        .map((e) => MapEntry(comments.indexOf(e), _quotes(e)))
        .toDescendingLength();

    for (final entry in sorted) {
      final index = entry.key;
      final quote = entry.value;
      final clean = quote.clean().clean();

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

  Iterable<String> _quotes(Comment comment) {
    final body = parse(comment.article).body;
    final italics = body.querySelectorAll('i').map((e) => e.innerHtml);
    return _quotesRegExp
        .allMatches(body.text)
        .map((e) => e[0])
        .where((e) => !italics.contains(e))
        .followedBy(italics);
  }

  Comment _colorize(Comment comment, String from, String span) {
    final article = comment.article
        // html parser gives '<br />' as '<br>'
        .replaceAll('<br />', '<br>')
        .replaceFirst(from, span);

    assert(
      article != comment.article,
      'no quote\n\n'
      '$from\n\n'
      'in comment\n\n'
      '${comment.article}\n\n'
      'colorized',
    );

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
  final String url;
  final String date;
  final String title;

  Link({this.url, this.date, this.title});

  Link.fromMap(
    Map map,
  ) : this(
          url: map[urlKey],
          date: map[dateKey],
          title: map[titleKey],
        );

  Link.fromHtml(
    dom.Element a,
    dom.Element abbr,
  ) : this(
          url: a.attributes['href'],
          date: abbr.text,
          title: a.text,
        );

  Map<String, String> toMap() => {urlKey: url, dateKey: date, titleKey: title};

  @override
  String toString() => toMap().toString();
}

class Article {
  Article(
    this.link,
    this.text,
    this.comments,
  );

  final Link link;
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
