import 'package:exolutio/src/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';
import '../common.dart';

class ArticleScreen extends StatefulWidget {
  ArticleScreen(this.context);

  final context;

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final _model = locator<Model>();

  double get _currentPosition => _scroll.position.pixels;

  Article _data;
  String _title;
  ScrollController _scroll;

  double _jumpedFrom;
  bool get _jumped => _jumpedFrom != null;
  bool get _reachedJumpStart => _currentPosition >= _jumpedFrom;

  @override
  void initState() {
    var arguments = _getScreenArguments(widget.context);
    _articleAsFuture(arguments[1]).then(_initState);
    _title = arguments[0];
    super.initState();
  }

  void _initState(Article value) {
    _data = value;

    _scroll = ScrollController(
      initialScrollOffset: _model.getPosition(
        _data,
      ),
    )..addListener(() {
        if (_jumped && !_reachedJumpStart) {
          return;
        }
        _setNotJumped(animate: false);
        _model.savePosition(
          _data,
          _currentPosition,
        );
      });

    setState(() {});
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _jumped ? _setNotJumped : _setJumped,
        child: Icon(_jumped ? Icons.arrow_downward : Icons.arrow_upward),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            _buildAppBar(),
            if (_data != null) _buildHtml(),
            if (_data != null) _buildComments(),
            if (_data == null) SliverProgressIndicator(),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: AppBarHeight,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(_title),
      ),
      centerTitle: true,
    );
  }

  SliverToBoxAdapter _buildComments() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 50,
          child: RaisedButton(
            onPressed: () => launch(_data.commentsUrl),
            child: Text('Комментарии'),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHtml() {
    final style = Style(fontSize: FontSize(20));
    return SliverToBoxAdapter(
      child: Html(
        onLinkTap: launch,
        data: _data.text,
        style: {
          'p': style,
          'div': style,
          'article': style,
        },
      ),
    );
  }

  void _setJumped() {
    if (!_jumped) {
      _animateTo(0);

      setState(() {
        _jumpedFrom = _currentPosition;
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

  List _getScreenArguments(BuildContext context) {
    return ModalRoute.of(context).settings.arguments as List;
  }

  Future<Article> _articleAsFuture(Link argument) {
    var futureOr = _model.article(argument);
    if (futureOr is Article) {
      return Future.value(futureOr);
    } else {
      return futureOr;
    }
  }
}
