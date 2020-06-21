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

  Future<List<Link>> get links => Future.value(
        <Link>[
          Link('1182866', 'Письмо 1'),
          Link('1184227', 'Письмо 2'),
        ],
      );

  Future<Article> article(Link link) => Client()
      .get('${Root + link.id}.html')
      .then((value) => parse(value.body))
      .then((value) => Article(
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
  Link(this.id, this.title);

  final String id;
  final String title;
}

class Article {
  Article(this.text, this.comments);

  final String text;
  final String comments;
}
