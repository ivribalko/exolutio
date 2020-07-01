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
