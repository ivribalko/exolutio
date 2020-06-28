import 'dart:async';

import 'package:exolutio/src/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';
import '../common.dart';

const _jumpDuration = Duration(milliseconds: 300);

class ArticleScreen extends StatefulWidget {
  ArticleScreen(this.context);

  final context;

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final _model = locator<Model>();
  final _scroll = AutoScrollController();
  _Jumper _jumper;

  Article _data;
  String _title;

  @override
  void initState() {
    var arguments = _getScreenArguments(widget.context);
    _articleAsFuture(arguments[1]).then(_initStateWithData);
    _title = arguments[0];
    _jumper = _Jumper(this);
    _jumper.mode.listen((value) => setState(() {}));
    _jumper.position.listen(_animateTo);

    _scroll.addListener(() {
      if (!_jumper.jumped || _jumper.returned) {
        _jumper.clear();
        _model.savePosition(
          _data,
          _scroll.offset,
        );
      }
    });

    super.initState();
  }

  void _initStateWithData(Article value) {
    _data = value;
    _animateTo(_model.getPosition(_data));
    setState(() {});
  }

  @override
  void dispose() {
    _jumper.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed:
            _jumper.jumped ? _jumper.setBacked : _jumper.setJumpedComment,
        child: Icon(_jumper.jumped ? Icons.arrow_downward : Icons.arrow_upward),
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
              (e) => AutoScrollTag(
                index: _data.comments.indexOf(e),
                controller: _scroll,
                key: ValueKey(_data.comments.indexOf(e)),
                child: Card(
                  color: e.dname == 'evo_lutio'
                      ? Colors.blueAccent.withAlpha(125)
                      : null,
                  child: Column(
                    children: <Widget>[
                      Text(
                        e.dname,
                        style: TextStyle(
                          color: Theme.of(context).disabledColor,
                          shadows: <Shadow>[
                            Shadow(
                              offset: Offset(0.0, 1.0),
                              blurRadius: 3.0,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
                      Html(data: e.article),
                    ],
                  ),
                ),
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

  void _animateTo(double position) {
    if (position != null) {
      _scroll.animateTo(
        position,
        duration: _jumpDuration,
        curve: Curves.easeOutExpo,
      );
    }
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

enum JumpMode {
  none,
  start,
  comment,
  back,
}

class _Jumper {
  bool _jumpedUp;
  double _jumpedFrom;
  final _ArticleScreenState reading;
  final mode = PublishSubject<JumpMode>();
  final position = PublishSubject<double>();

  _Jumper(this.reading);

  void dispose() {
    mode.close();
    position.close();
  }

  bool get jumped => _mode != JumpMode.none;

  bool get returned {
    return _jumpedUp
        ? reading._scroll.offset >= _jumpedFrom
        : reading._scroll.offset <= _jumpedFrom;
  }

  JumpMode _mode = JumpMode.none;
  set _modeSetter(JumpMode event) {
    _mode = event;
    mode.add(event);

    switch (event) {
      case JumpMode.none:
        position.add(null);
        break;
      case JumpMode.start:
        position.add(0);
        break;
      case JumpMode.comment:
        // controlled by plugin
        break;
      case JumpMode.back:
        position.add(_jumpedFrom);
        break;
      default:
        throw UnsupportedError(event.toString());
    }
  }

  void setJumpedStart() {
    _jumpedUp = true;
    _jumpedFrom = reading._scroll.offset;
    _modeSetter = JumpMode.start;
  }

  void setJumpedComment() {
    _jumpedUp = false;
    _jumpedFrom = reading._scroll.offset;
    _modeSetter = JumpMode.comment;
    reading._scroll.scrollToIndex(
      0,
      duration: _jumpDuration,
      preferPosition: AutoScrollPosition.begin,
    );
    reading.setState(() {});
  }

  void setBacked() {
    if (jumped) {
      _modeSetter = JumpMode.back;
      clear();
    }
  }

  void clear() {
    if (jumped) {
      _jumpedUp = null;
      _jumpedFrom = null;
      _modeSetter = JumpMode.none;
    }
  }
}
