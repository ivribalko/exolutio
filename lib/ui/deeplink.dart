import 'package:exolutio/main.dart';
import 'package:exolutio/src/firebase.dart';
import 'package:exolutio/src/model.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

class Router {
  final BuildContext context;
  final _firebase = locator<Firebase>();

  Router(
    this.context,
  ) {
    _checkInitialLink().then((_) => initDynamicLinks());
  }

  void initDynamicLinks() async {
    _firebase.onLink(
      onSuccess: _follow,
      onError: (e) async => print(e),
    );
  }

  Future _checkInitialLink() async {
    _follow((await _firebase.getInitialLink()));
  }

  Future _follow(PendingDynamicLinkData data) async {
    var deep = data?.link;
    if (deep != null) {
      final map = deep.queryParameters;
      final link = Link(map['title'], map['url']);
      print('following link to ${deep.path}: '
          'of title: ${link.title} '
          'and url: ${link.url}');
      Navigator.of(context).pushNamed(
        deep.path,
        arguments: link,
      );
    }
  }
}
