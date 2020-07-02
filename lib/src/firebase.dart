import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class Firebase {
  Future<String> getLink(String article) async {
    var parameters = DynamicLinkParameters(
      uriPrefix: 'https://exolutio.page.link',
      link: Uri.parse('https://exolutio/article?id=$article'),
      androidParameters: AndroidParameters(
        packageName: "com.ivanrybalko.exolutio",
      ),
    );

    var shortLink = await parameters.buildShortLink();

    return shortLink.shortUrl.toString();
  }
}
