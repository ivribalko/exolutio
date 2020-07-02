import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class Firebase {
  Future<String> getArticleLink(String url) async {
    var parameters = DynamicLinkParameters(
      uriPrefix: 'https://exolutio.page.link',
      link: Uri.parse('https://exolutio/article?url=$url'),
      androidParameters: AndroidParameters(
        packageName: "com.ivanrybalko.exolutio",
      ),
    );

    return (await parameters.buildShortLink()).shortUrl.toString();
  }
}
