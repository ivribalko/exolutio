import 'dart:async';
import 'dart:math';

import 'package:exolutio/src/firebase.dart';
import 'package:exolutio/src/html_model.dart';
import 'package:exolutio/src/meta_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';
import '../common.dart';
import '../view_model.dart';

const _jumpDuration = Duration(milliseconds: 300);

class ReadScreen extends StatefulWidget {
  ReadScreen(this.context);

  final context;

  @override
  _ReadScreenState createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  final _meta = locator<MetaModel>();
  final _html = locator<HtmlViewModel>();
  final _scroll = AutoScrollController();

  _Jumper _jumper;
  Article _data;
  String _title;

  @override
  void initState() {
    final link = _getRouteArguments(widget.context) as Link;
    _title = link.title;
    _articleAsFuture(link).then(_initStateWithData);
    _jumper = _Jumper(this);
    _jumper.mode.listen((value) => setState(() {}));
    _jumper.position.listen(_animateTo);

    _scroll.addListener(() {
      if (!_jumper.jumped || _jumper.returned) {
        _jumper.clear();
        _meta.savePosition(
          _data,
          _scroll.offset,
        );
      }
    });

    super.initState();
  }

  void _initStateWithData(Article value) {
    _data = value;
    _animateTo(_meta.getPosition(_data));
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
    return WillPopScope(
      onWillPop: () async => !_jumper.setBacked(),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed:
              _jumper.jumped ? _jumper.setBacked : _jumper.setJumpedStart,
          child: Icon(_floatingIcon),
        ),
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              Selector<MetaModel, double>(
                selector: (_, meta) => meta.fontScale,
                builder: (_, __, ___) => CustomScrollView(
                  controller: _scroll,
                  slivers: [
                    _buildAppBar(),
                    if (_data != null) _buildHtml(),
                    if (_data != null) _buildComments(),
                    if (_data != null) _buildFloatingMargin(),
                    if (_data == null) SliverProgressIndicator(),
                  ],
                ),
              ),
              _BottomBar(this),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _floatingIcon {
    switch (_jumper.mode.value) {
      case JumpMode.start:
        return Icons.arrow_downward;
      default:
        return Icons.arrow_upward;
    }
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
                  elevation: 3,
                  color: e.dname == e.poster ? _authorColor : null,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            '  ${'↳ ' * e.level} ${e.dname}',
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .subtitle2
                                  .fontSize,
                              color: e.dname == e.poster
                                  ? Colors.white
                                  : Theme.of(context).disabledColor,
                              shadows: <Shadow>[
                                Shadow(
                                  offset: Offset(0.0, 1.0),
                                  blurRadius: 2.0,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Html(
                        data: '<article>${e.article}</article>',
                        style: e.dname == e.poster ? _authorStyle : _htmlStyle,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildHtml() {
    return SliverToBoxAdapter(
      child: Html(
        onLinkTap: _onLinkTap,
        data: _data.text,
        style: _htmlStyle,
      ),
    );
  }

  double get _fontSize {
    return Theme.of(context).textTheme.bodyText1.fontSize * _meta.fontScale;
  }

  Map<String, Style> get _htmlStyle => {
        'article': Style(fontSize: FontSize(_fontSize)),
        '.quote': Style(fontSize: FontSize(_fontSize), color: _accentColor),
      };

  Map<String, Style> get _authorStyle => {
        'article': Style(fontSize: FontSize(_fontSize), color: Colors.white),
        '.quote': Style(fontSize: FontSize(_fontSize), color: _accentColor),
      };

  Color get _authorColor => Theme.of(context).brightness == Brightness.dark
      ? _accentColor.withAlpha(100)
      : _accentColor;

  Color get _accentColor => Theme.of(context).accentColor;

  void _onLinkTap(String url) {
    if (url.startsWith(CommentLink)) {
      final index = url.substring(CommentLink.length);
      _jumper.setJumpedComment(int.parse(index));
    } else {
      launch(url);
    }
  }

  Widget _buildFloatingMargin() {
    return SliverToBoxAdapter(child: Container(height: 80));
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

  Object _getRouteArguments(BuildContext context) {
    return ModalRoute.of(context).settings.arguments;
  }

  Future<Article> _articleAsFuture(Link argument) {
    var futureOr = _html.article(argument);
    if (futureOr is Article) {
      return Future.value(futureOr);
    } else {
      return futureOr;
    }
  }
}

class _BottomBar extends StatefulWidget {
  final _ReadScreenState reading;

  _BottomBar(this.reading);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  static const double _height = 85;
  final _meta = locator<MetaModel>();
  final firebase = locator<Firebase>();
  get _scrollController => widget.reading._scroll;
  double _offset = 0, _delta = 0, _offsetWas = _height;

  @override
  void initState() {
    _scrollController.addListener(
      () => setState(
        () {
          final offset = _scrollController.offset;
          _delta += (offset - _offsetWas);
          _delta = min(max(0, _delta), _height);
          _offsetWas = offset;
          _offset = -_delta;
        },
      ),
    );
    super.initState();
  }

  Article get _article => widget.reading._data;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: _offset,
      width: MediaQuery.of(context).size.width,
      child: Container(
        height: _height,
        color: Theme.of(context).bottomAppBarColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _flatButton(Icons.share, _shareLink),
            _flatButton(Icons.format_size, _meta.nextScale),
          ],
        ),
      ),
    );
  }

  Widget _flatButton(IconData icon, Function onPressed) {
    return FlatButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Container(),
      shape: CircleBorder(),
    );
  }

  void _shareLink() async => _article?.link?.url == null
      ? null
      : Share.share(
          '${_article.link.title}: '
          '${await firebase.getArticleLink(_article.link)}',
        );
}

class _Progress extends StatefulWidget {
  final _ReadScreenState reading;

  _Progress(this.reading);

  @override
  _ProgressState createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  AutoScrollController get _scroll => widget.reading._scroll;

  @override
  void initState() {
    _scroll.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reading._data == null) {
      return LinearProgressIndicator();
    }

    var position = _scroll.position;
    var value = position.pixels / position.maxScrollExtent;
    if (value.isInfinite || value.isNaN) {
      value = 0;
    }
    return GestureDetector(
      onTapDown: (e) => _jump(e.localPosition, context),
      onHorizontalDragUpdate: (e) => _jump(e.localPosition, context),
      child: LinearProgressIndicator(value: value),
    );
  }

  void _jump(Offset offset, BuildContext context) {
    final relative = offset.dx / context.size.width;
    return _scroll.jumpTo(_scroll.position.maxScrollExtent * relative);
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
  final _ReadScreenState reading;
  final mode = BehaviorSubject<JumpMode>()..add(JumpMode.none);
  final position = PublishSubject<double>();

  _Jumper(this.reading);

  void dispose() {
    mode.close();
    position.close();
  }

  bool get jumped => mode.value != JumpMode.none;

  bool get returned {
    return _jumpedUp
        ? reading._scroll.offset >= _jumpedFrom
        : reading._scroll.offset <= _jumpedFrom;
  }

  set _modeSetter(JumpMode event) {
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

  void setJumpedComment(int index) {
    _jumpedUp = false;
    _jumpedFrom = reading._scroll.offset;
    _modeSetter = JumpMode.comment;
    reading._scroll.scrollToIndex(
      index,
      duration: _jumpDuration,
      preferPosition: AutoScrollPosition.begin,
    );
    // ignore: invalid_use_of_protected_member
    reading.setState(() {}); // TODO
  }

  bool setBacked() {
    if (jumped) {
      _modeSetter = JumpMode.back;
      clear();
      return true;
    } else {
      return false;
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
