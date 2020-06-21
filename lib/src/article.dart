class ArticleModel {
  final Future<Article> data = Future.delayed(
    Duration(seconds: 1),
  ).then(
    (_) => Article(),
  );
}

class Article {
  String text = 'result';
}
