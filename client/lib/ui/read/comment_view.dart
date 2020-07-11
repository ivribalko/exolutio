import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:shared/comment_data.dart';

class CommentView extends StatelessWidget {
  const CommentView({
    Key key,
    @required CommentData data,
    @required Color authorColor,
    @required this.context,
    @required Map<String, Style> authorStyle,
    @required Map<String, Style> htmlStyle,
  })  : _data = data,
        _authorColor = authorColor,
        _avatarMove = const EdgeInsets.only(top: 5.0),
        _authorStyle = authorStyle,
        _htmlStyle = htmlStyle,
        super(key: key);

  final CommentData _data;
  final Color _authorColor;
  final BuildContext context;
  final EdgeInsets _avatarMove;
  final Map<String, Style> _authorStyle;
  final Map<String, Style> _htmlStyle;

  Widget _divider(Color color) {
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
        _buildHtmlCard(context),
        _buildAvatar(context),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Column(
      children: <Widget>[
        if (_data.level == 1) _divider(Colors.transparent),
        Align(
          alignment: Alignment.topRight,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: _borderColor(context),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(_data.userpic),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHtmlCard(BuildContext context) {
    return Column(
      children: <Widget>[
        if (_data.level == 1) _divider(Theme.of(context).disabledColor),
        Padding(
          padding: _avatarMove, // move avatar higher
          child: Card(
            shape: _roundedRectangleBorder(context),
            elevation: 2,
            color: _data.dname == _data.poster
                ? _authorColor
                : Theme.of(context).bottomAppBarColor,
            child: Column(
              children: <Widget>[
                _buildLevelAndName(context),
                _buildHtmlText(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHtmlText() {
    return Html(
      data: '<article>${_data.article}</article>',
      style: _data.dname == _data.poster ? _authorStyle : _htmlStyle,
    );
  }

  Widget _buildLevelAndName(BuildContext context) {
    return Row(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: 7.0, top: 7.0),
          child: Text(
            '${_data.level}↳ ${_data.dname}',
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.subtitle2.fontSize,
              color: _data.dname == _data.poster
                  ? Colors.white
                  : Theme.of(context).disabledColor,
            ),
          ),
        ),
      ],
    );
  }

  RoundedRectangleBorder _roundedRectangleBorder(BuildContext context) {
    return RoundedRectangleBorder(
      side: BorderSide(
        color: _borderColor(context),
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(10),
    );
  }

  Color _borderColor(BuildContext context) {
    return Theme.of(context).disabledColor;
  }
}
