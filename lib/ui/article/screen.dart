import 'package:flutter/material.dart';

class ArticleScreen extends StatelessWidget {
  const ArticleScreen(this.data);

  final String data;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(data));
  }
}
