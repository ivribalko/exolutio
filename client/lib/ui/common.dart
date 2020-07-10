import 'package:flutter/material.dart';
import 'package:shared/html_model.dart';

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

bool isDarkTheme(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}
