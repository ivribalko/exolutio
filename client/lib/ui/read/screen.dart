import 'dart:async';
import 'dart:math';

import 'package:client/src/comment.dart';
import 'package:client/src/firebase.dart';
import 'package:client/src/html_model.dart';
import 'package:client/src/meta_model.dart';
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

  StreamSubscription _loading;
  _Jumper _jumper;
  Article _data;
  String _title;

  @override
  void initState() {
    final link = _getRouteArguments(widget.context) as Link;
    _title = link.title;
    _loading = _articleAsFuture(link).asStream().listen(_initStateWithData);
    _jumper = _Jumper(this);
    _jumper.mode.listen((value) => setState(() {}));
    _jumper.position.listen(_animateTo);

    _scroll.addListener(() {
      if (_jumper.returned) {
        _jumper.clear();
        _meta.savePosition(
          link,
          _scroll.offset,
          _scroll.position.maxScrollExtent,
        );
      }
    });

    super.initState();
  }

  void _initStateWithData(Article value) {
    _data = value;
    _meta.savePosition(_data.link, 0, _scroll.position.maxScrollExtent);
    _animateTo(_meta.getPosition(_data.link));
    setState(() {});
  }

  @override
  void dispose() {
    _loading.cancel();
    _jumper.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_jumper.goBack(),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _jumper.jumped ? _jumper.goBack : _jumper.goStart,
          child: Icon(_floatingIcon),
        ),
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              Selector<MetaModel, double>(
                selector: (_, meta) => meta.fontSize,
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
              _Progress(this),
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
                child: _Comment(
                  comment: e,
                  authorColor: _authorColor,
                  context: context,
                  authorStyle: _authorStyle,
                  htmlStyle: _htmlStyle,
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

  double get _fontSize => _meta.fontSize;

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
      _jumper.goComment(int.parse(index));
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

class _Comment extends StatelessWidget {
  const _Comment({
    Key key,
    @required Comment comment,
    @required Color authorColor,
    @required this.context,
    @required Map<String, Style> authorStyle,
    @required Map<String, Style> htmlStyle,
  })  : _comment = comment,
        _authorColor = authorColor,
        _avatarMove = const EdgeInsets.only(top: 5.0),
        _authorStyle = authorStyle,
        _htmlStyle = htmlStyle,
        super(key: key);

  final Comment _comment;
  final Color _authorColor;
  final BuildContext context;
  final EdgeInsets _avatarMove;
  final Map<String, Style> _authorStyle;
  final Map<String, Style> _htmlStyle;

  Widget _divider({Color color}) {
    return Padding(
      padding: _avatarMove,
      child: Divider(
        height: 20,
        thickness: 3,
        indent: 50,
        endIndent: 50,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            if (_comment.level == 1) _divider(color: null),
            Padding(
              padding: _avatarMove, // move avatar higher
              child: Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: _borderColor(context),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                color: _comment.dname == _comment.poster
                    ? _authorColor
                    : Theme.of(context).bottomAppBarColor,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(left: 7.0, top: 7.0),
                          child: Text(
                            '${_comment.level}↳ ${_comment.dname}',
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .subtitle2
                                  .fontSize,
                              color: _comment.dname == _comment.poster
                                  ? Colors.white
                                  : Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Html(
                      data: '<article>${_comment.article}</article>',
                      style: _comment.dname == _comment.poster
                          ? _authorStyle
                          : _htmlStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Column(
          children: <Widget>[
            if (_comment.level == 1) _divider(color: Colors.transparent),
            Align(
              alignment: Alignment.topRight,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: _borderColor(context),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(_comment.userpic),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _borderColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }
}

class _BottomBar extends StatefulWidget {
  final _ReadScreenState reading;

  _BottomBar(this.reading);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  static const double _height = 60;
  final _meta = locator<MetaModel>();
  final firebase = locator<Firebase>();
  double _offset = 0, _delta = 0, _offsetWas = _height;
  AutoScrollController get _scroll => widget.reading._scroll;

  @override
  void initState() {
    _scroll.addListener(
      () => setState(
        () {
          final offset = _scroll.offset;
          if (widget.reading._jumper.jumped) {
            _delta += (offset - _offsetWas).abs();
          } else {
            _delta += (offset - _offsetWas);
          }
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
        decoration: _shadowWhenLight(context),
        height: _height,
        color: _colorWhenDark(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _flatButton(Icons.share, _shareLink),
            _flatButton(Icons.format_size, _meta.nextFontSize),
          ],
        ),
      ),
    );
  }

  Color _colorWhenDark(BuildContext context) {
    return isDarkTheme(context) ? Theme.of(context).bottomAppBarColor : null;
  }

  BoxDecoration _shadowWhenLight(BuildContext context) {
    if (isDarkTheme(context)) {
      return null;
    } else {
      return BoxDecoration(
        color: Theme.of(context).bottomAppBarColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      );
    }
  }

  Widget _flatButton(IconData icon, Function onPressed) {
    return Material(
      shape: CircleBorder(),
      color: Theme.of(context).bottomAppBarColor,
      child: IconButton(
        iconSize: 24,
        onPressed: onPressed,
        icon: Icon(icon),
        enableFeedback: false,
      ),
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
    return Align(
      alignment: Alignment.bottomCenter,
      child: _buildProgress(context),
    );
  }

  Widget _buildProgress(BuildContext context) {
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
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.only(top: 15),
          child: LinearProgressIndicator(value: value),
        ),
      ),
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

  double get _offset => reading._scroll.offset;

  bool get jumped => mode.value != JumpMode.none;

  bool get returned {
    if (!jumped) {
      return true;
    } else {
      return _jumpedUp ? _offset >= _jumpedFrom : _offset <= _jumpedFrom;
    }
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

  void goStart() {
    _jumpedUp = true;
    _jumpedFrom = _offset;
    _modeSetter = JumpMode.start;
  }

  void goComment(int index) {
    _jumpedUp = false;
    _jumpedFrom = _offset;
    _modeSetter = JumpMode.comment;
    reading._scroll.scrollToIndex(
      index,
      duration: _jumpDuration,
      preferPosition: AutoScrollPosition.begin,
    );
    // ignore: invalid_use_of_protected_member
    reading.setState(() {}); // TODO
  }

  bool goBack() {
    if (jumped) {
      _modeSetter = JumpMode.back;
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
