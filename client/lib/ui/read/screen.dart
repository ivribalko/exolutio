import 'dart:async';
import 'dart:math';

import 'package:client/src/firebase.dart';
import 'package:client/src/meta_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:share/share.dart';
import 'package:shared/html_model.dart';
import 'package:shared/loader.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../locator.dart';
import '../common.dart';
import '../routes.dart';
import '../view_model.dart';
import 'comment_view.dart';
import 'jumper.dart';
import 'progress_view.dart';

class ReadScreen extends StatefulWidget {
  ReadScreen(this.context);

  final context;

  @override
  _ReadScreenState createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> with WidgetsBindingObserver {
  final _meta = locator<MetaModel>();
  final _html = locator<HtmlViewModel>();
  final _scroll = AutoScrollController();

  StreamSubscription _loading;
  ScrollPosition _lastScroll;
  Jumper _jumper;
  Article _data;
  String _title;

  @override
  void initState() {
    final link = _getRouteArguments(widget.context) as Link;
    _title = link.title;
    _loading = _articleAsFuture(link).asStream().listen(_initStateWithData);
    _jumper = Jumper(_scroll);
    _jumper.mode.listen((value) => setState(() {}));
    _jumper.position.listen(_animateTo);

    _scroll.addListener(() {
      if (_jumper.returned) {
        _lastScroll = _scroll.position;
        _jumper.clear();
      }
    });

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  void _initStateWithData(Article value) {
    _data = value;
    _animateTo(_meta.getPosition(_data.link));
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _savePosition();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _savePosition();
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
              ProgressView(this._scroll),
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
                child: CommentView(
                  data: e,
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
    } else if (url.startsWith(Root)) {
      safePushNamed(context, Routes.read, Link(url: url, date: '', title: ''));
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
        duration: jumpDuration,
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

  void _savePosition() {
    if (_lastScroll != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => _meta.savePosition(
          _data.link,
          _lastScroll.pixels,
          _lastScroll.maxScrollExtent,
        ),
      );
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
            _flatButton(Icons.text_format, _meta.nextFont),
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
