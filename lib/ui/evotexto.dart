import 'package:evotexto/src/model.dart';
import 'package:flutter/material.dart';

import 'article/screen.dart';
import 'home/screen.dart';

class Evotexto extends StatelessWidget {
  const Evotexto(this.data);

  final List<Link> data;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evotexto',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      routes: {
        '/': (context) => HomeScreen(data),
        '/read': (context) => ArticleScreen(),
      },
    );
  }
}
