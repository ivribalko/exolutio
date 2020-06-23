import 'package:flutter/material.dart';

import 'home/screen.dart';
import 'read/screen.dart';

class Exolutio extends StatelessWidget {
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
        '/read': (context) => ArticleScreen(context),
      },
      // https://github.com/Sub6Resources/flutter_html/issues/294#issuecomment-637318948
      builder: (BuildContext context, Widget child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
        child: child,
      ),
    );
  }
}
