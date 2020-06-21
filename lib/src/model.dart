import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';

class ArticleModel {
  static const String Root = 'https://evo-lutio.livejournal.com/';
  static const String Address = '1182866.html'; // 1184227
  static const List<String> Contents = [
    'div.b-singlepost-bodywrapper',
    'div.aentry-post__text.aentry-post__text--view',
  ];
  static const String Comments = 'div.acomments")';

  Future<List<Link>> get links => Client()
      .get(Root)
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
            'COMMENTS NOT IMPLEMENTED',
          ));

  String _getArticleText(Document value) {
    return Contents.map(value.querySelector)
        .firstWhere((element) => element?.text?.isNotEmpty ?? false)
        .text;
  }
}

class Link {
  Link(this.url, this.title);

  final String url;
  final String title;
}

class Article {
  Article(this.title, this.text, this.comments);

  final String title;
  final String text;
  final String comments;
}
