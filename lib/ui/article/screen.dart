import 'package:evotexto/src/model.dart';
import 'package:flutter/material.dart';

class ArticleScreen extends StatelessWidget {
  ArticleScreen(this.data);

  final Article data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Text(data.text),
              Text(data.comments),
            ],
          ),
        ),
      ),
    );
  }
}
