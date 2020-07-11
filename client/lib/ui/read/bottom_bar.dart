import 'dart:math';

import 'package:client/src/firebase.dart';
import 'package:client/src/meta_model.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:share/share.dart';
import 'package:shared/html_model.dart';

import '../../locator.dart';
import '../common.dart';
import 'jumper.dart';

class BottomBar extends StatefulWidget {
  final Article data;
  final Jumper jumper;
  final AutoScrollController scroll;

  const BottomBar(this.data, this.jumper, this.scroll);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  static const double _height = 60;
  final _meta = locator<MetaModel>();
  final firebase = locator<Firebase>();
  double _offset = 0, _delta = 0, _offsetWas = _height;
  AutoScrollController get _scroll => widget.scroll;

  @override
  void initState() {
    _scroll.addListener(
      () => setState(
        () {
          final offset = _scroll.offset;
          if (widget.jumper.jumped) {
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

  void _shareLink() async {
    return Share.share(
      '${widget.data.link.title}: '
      '${await firebase.getArticleLink(widget.data.link)}',
    );
  }
}
