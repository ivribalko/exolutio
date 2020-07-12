import 'dart:async';

import 'package:client/src/meta_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:shared/comment_data.dart';
import 'package:shared/html_model.dart';
import 'package:shared/loader.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../locator.dart';
import '../common.dart';
import '../routes.dart';
import '../view_model.dart';
import 'bottom_bar.dart';
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
    final link = _getRouteArguments(widget.context) as LinkData;
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
              if (_data != null) BottomBar(_data, _jumper, _scroll),
              if (_data != null) ProgressView(this._scroll),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: AppBarHeight,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(_title),
      ),
      centerTitle: true,
    );
  }

  Widget _buildComments() {
    return Selector<MetaModel, double>(
      selector: (_, data) => data.fontSize,
      builder: (_, __, ___) => SliverList(
        delegate: SliverChildListDelegate(
          _data.comments.map(_buildComment).toList(),
        ),
      ),
    );
  }

  Widget _buildComment(CommentData e) {
    return AutoScrollTag(
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
    return _meta.fontSize;
  }

  Map<String, Style> get _htmlStyle {
    return {
      'article': Style(fontSize: FontSize(_fontSize)),
      '.quote': Style(fontSize: FontSize(_fontSize), color: _accentColor),
    };
  }

  Map<String, Style> get _authorStyle {
    return {
      'article': Style(fontSize: FontSize(_fontSize), color: Colors.white),
      '.quote': Style(fontSize: FontSize(_fontSize), color: _accentColor),
    };
  }

  Color get _authorColor {
    return Theme.of(context).brightness == Brightness.dark
        ? _accentColor.withAlpha(100)
        : _accentColor;
  }

  Color get _accentColor {
    return Theme.of(context).accentColor;
  }

  void _onLinkTap(String url) {
    if (url.startsWith(CommentLink)) {
      final index = url.substring(CommentLink.length);
      _jumper.goComment(int.parse(index));
    } else if (url.startsWith(Root)) {
      safePushNamed(
          context, Routes.read, LinkData(url: url, date: '', title: ''));
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

  Future<Article> _articleAsFuture(LinkData argument) {
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
