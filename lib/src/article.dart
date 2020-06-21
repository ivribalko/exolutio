import 'package:html/parser.dart';
import 'package:http/http.dart';

class ArticleModel {
  static const String Root = 'https://evo-lutio.livejournal.com/';
  static const String Address = '1184227.html';
  static const String Content = 'div.aentry-post__text.aentry-post__text--view';

  Future<Article> get data => Client()
      .get(Root + Address)
      .then((value) => parse(value.body))
      .then((value) => value.querySelector(Content).text)
      .then((value) => Article(value));
}

class Article {
  final String text;

  Article(this.text);
}
