import 'package:exolutio/ui/routes.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import 'html_model.dart';

class Firebase {
  Future<String> getArticleLink(Link link) async {
    final parameters = DynamicLinkParameters(
      uriPrefix: 'https://exolutio.page.link',
      link: Uri.parse('https://exolutio${Routes.read}?'
          '$titleKey=${link.title}&'
          '$urlKey=${link.url}'),
      androidParameters: AndroidParameters(
        packageName: "com.ivanrybalko.exolutio",
      ),
    );

    return (await parameters.buildShortLink()).shortUrl.toString();
  }

  Future<PendingDynamicLinkData> getInitialLink() => _links.getInitialLink();

  FirebaseDynamicLinks get _links => FirebaseDynamicLinks.instance;

  void onLink({OnLinkSuccessCallback onSuccess, OnLinkErrorCallback onError}) {
    _links.onLink(onSuccess: onSuccess, onError: onError);
  }
}
