import 'package:rxdart/rxdart.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

enum JumpMode {
  none,
  start,
  comment,
  back,
}

const jumpDuration = Duration(milliseconds: 300);

class Jumper {
  bool _jumpedUp;
  double _jumpedFrom;
  final AutoScrollController scroll;
  final mode = BehaviorSubject<JumpMode>()..add(JumpMode.none);
  final position = PublishSubject<double>();

  Jumper(this.scroll);

  void dispose() {
    mode.close();
    position.close();
  }

  double get _offset => scroll.offset;

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
    scroll.scrollToIndex(
      index,
      duration: jumpDuration,
      preferPosition: AutoScrollPosition.begin,
    );
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
