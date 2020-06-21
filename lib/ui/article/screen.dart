import 'package:evotexto/src/model.dart';
import 'package:flutter/material.dart';

class ArticleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Article args = ModalRoute.of(context).settings.arguments;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text(args.text),
            Text(args.comments),
          ],
        ),
      ),
    );
  }
}
