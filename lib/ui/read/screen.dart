import 'package:exolutio/src/model.dart';
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
  final _model = locator<Model>();

  double _jumpedFrom;
  bool get _jumped => _jumpedFrom != null;
  bool get _reachedJumpStart => _currentPosition() >= _jumpedFrom;

  ScrollController _scroll;

  @override
  void initState() {
    _scroll = ScrollController(
      initialScrollOffset: _model.getPosition(
        widget.data,
      ),
    )..addListener(() {
        if (_jumped && !_reachedJumpStart) {
          return;
        }
        _setNotJumped(animate: false);
        _model.savePosition(
          widget.data,
          _currentPosition(),
        );
      });
    super.initState();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Style(fontSize: FontSize(20));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _jumped ? _setNotJumped : _setJumped,
        child: Icon(_jumped ? Icons.arrow_downward : Icons.arrow_upward),
      ),
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

  void _setJumped() {
    if (!_jumped) {
      _animateTo(0);

      setState(() {
        _jumpedFrom = _currentPosition();
      });
    }
  }

  void _setNotJumped({bool animate = true}) {
    if (_jumped) {
      if (animate) {
        _animateTo(_jumpedFrom);
      }

      setState(() {
        _jumpedFrom = null;
      });
    }
  }

  void _animateTo(double position) {
    _scroll.animateTo(
      position,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutExpo,
    );
  }

  double _currentPosition() {
    return _scroll.position.pixels;
  }
}
