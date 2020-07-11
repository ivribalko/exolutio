import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ProgressView extends StatefulWidget {
  final AutoScrollController scroll;

  ProgressView(this.scroll);

  @override
  _ProgressViewState createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  AutoScrollController get _scroll => widget.scroll;

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
