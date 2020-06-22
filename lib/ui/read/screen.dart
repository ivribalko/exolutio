import 'package:evotexto/src/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';
import '../common.dart';

class ArticleScreen extends StatefulWidget {
  ArticleScreen(this.data);

  final Article data;

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final Model _model = locator<Model>();

  ScrollController _scroll;

  @override
  void initState() {
    _scroll = ScrollController(
      initialScrollOffset: _model.getPosition(
        widget.data,
      ),
    );
    _scroll.addListener(() {
      _model.savePosition(
        widget.data,
        _scroll.position.pixels,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = Style(fontSize: FontSize(20));
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              expandedHeight: AppBarHeight,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(widget.data.title),
              ),
              centerTitle: true,
              floating: true,
            ),
            SliverToBoxAdapter(
              child: Html(
                onLinkTap: launch,
                data: widget.data.text,
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
                    onPressed: () => launch(widget.data.commentsUrl),
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
