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

  Article _data;
  String _title;
  final ScrollController _scroll = ScrollController();

  double _jumpedFrom;
  bool get _jumped => _jumpedFrom != null;
  double get _currentPosition => _scroll.offset;

  @override
  void initState() {
    var arguments = _getScreenArguments(widget.context);
    _articleAsFuture(arguments[1]).then(_initState);
    _title = arguments[0];

    _scroll.addListener(() {
      if (_jumped && _currentPosition < _jumpedFrom) {
        return;
      }
      _setNotJumped(animate: false);
      _model.savePosition(
        _data,
        _currentPosition,
      );
    });

    super.initState();
  }

  void _initState(Article value) {
    _data = value;
    _animateTo(_model.getPosition(_data));

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
        child: Stack(
          children: <Widget>[
            CustomScrollView(
              controller: _scroll,
              slivers: [
                _buildAppBar(),
                if (_data != null) _buildHtml(),
                if (_data != null) _buildComments(),
                if (_data == null) SliverProgressIndicator(),
              ],
            ),
            Column(
              children: <Widget>[
                Spacer(),
                _Progress(this),
              ],
            ),
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

  Widget _buildComments() {
    return SliverList(
      delegate: SliverChildListDelegate(
        _data.comments
            .map(
              (e) => Card(
                child: Html(data: e.article),
              ),
            )
            .toList(),
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

class _Progress extends StatefulWidget {
  final _ArticleScreenState reading;

  _Progress(this.reading);

  @override
  _ProgressState createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  @override
  void initState() {
    widget.reading._scroll.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reading._data == null) {
      return LinearProgressIndicator();
    }

    var position = widget.reading._scroll.position;
    var value = position.pixels / position.maxScrollExtent;
    if (value.isInfinite || value.isNaN) {
      return LinearProgressIndicator();
    } else {
      return LinearProgressIndicator(value: value);
    }
  }
}
