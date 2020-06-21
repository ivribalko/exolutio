import 'package:evotexto/src/article.dart';
import 'package:flutter/material.dart';

import 'article/screen.dart';

class Evotexto extends StatelessWidget {
  const Evotexto(this.data);

  final Article data;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evotexto',
      home: ArticleScreen(data.text),
    );
  }
}
