import 'package:flutter/material.dart';

const double AppBarHeight = 100;

class SliverProgressIndicator extends StatelessWidget {
  const SliverProgressIndicator({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
