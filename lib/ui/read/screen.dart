import 'package:evotexto/src/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common.dart';

class ArticleScreen extends StatelessWidget {
  ArticleScreen(this.data);

  final Article data;

  @override
  Widget build(BuildContext context) {
    final style = Style(fontSize: FontSize(20));
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
              child: Html(
                onLinkTap: launch,
                data: data.text,
                style: {
                  'p': style,
                  'div': style,
                  'article': style,
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 50,
                  child: RaisedButton(
                    onPressed: () => launch(data.commentsUrl),
                    child: Text('Комментарии'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
