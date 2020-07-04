import 'package:exolutio/src/html_model.dart';
import 'package:flutter/material.dart';

const double AppBarHeight = 100;

class SliverProgressIndicator extends StatelessWidget {
  const SliverProgressIndicator({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Column(
        children: <Widget>[
          Spacer(),
          CircularProgressIndicator(),
          Spacer(),
        ],
      ),
    );
  }
}

void safePushNamed(BuildContext context, String path, Link link) {
  try {
    Navigator.of(context).pushNamed(
      path,
      arguments: link,
    );
  } catch (e) {
    print(e);
  }
}
