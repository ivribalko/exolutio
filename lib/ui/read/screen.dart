import 'package:evotexto/src/model.dart';
import 'package:flutter/material.dart';

import '../common.dart';

class ArticleScreen extends StatelessWidget {
  ArticleScreen(this.data);

  final Article data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: AppBarHeight,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(data.title),
              ),
              centerTitle: true,
              floating: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(data.text),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(data.comments),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
