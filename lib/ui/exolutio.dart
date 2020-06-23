import 'package:exolutio/src/model.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'home/screen.dart';
import 'read/screen.dart';

class Exolutio extends StatelessWidget {
  final _model = locator<Model>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exolutio',
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
      routes: {
        '/': (context) => HomeScreen(),
        '/read': (context) => ArticleScreen('TBD', _articleAsFuture(context)),
      },
      // https://github.com/Sub6Resources/flutter_html/issues/294#issuecomment-637318948
      builder: (BuildContext context, Widget child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
        child: child,
      ),
    );
  }

  Future<Article> _articleAsFuture(BuildContext context) {
    var futureOr = _model.article(ModalRoute.of(context).settings.arguments);
    if (futureOr is Article) {
      return Future.value(futureOr);
    } else {
      return futureOr;
    }
  }
}
