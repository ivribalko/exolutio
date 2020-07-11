import 'dart:async';
import 'dart:io';

import 'package:client/ui/view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared/html_model.dart';
import 'package:shared/loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLoader extends Mock implements Loader {}

class MockPreferences extends Mock implements SharedPreferences {}

final _files = <String, String>{
  'page': _baseAsset('.htm'),
  'single_page': _baseAsset('__single_page.htm'),
  'triple_page': _baseAsset('__triple_page.htm'),
  'quotes_with_quotes': _baseAsset('__quotes_with_quotes.htm'),
  'multiline_quotes': _baseAsset('__multiline_quotes.htm'),
  'thread': _baseAsset('__single_page_thread=add_two.htm'),
};

Loader _loader;
HtmlViewModel _model;
bool _update = false;

void main() {
  setUp(() {
    when((_loader = MockLoader()).page(any)).thenAnswer(_fromFile);
    _model = HtmlViewModel(_loader);
  });
  tearDown(() {
    _model.dispose();
  });

  group('comments count on ', () {
    Future _test(String name, int count) async {
      _mockFile(name);

      await _model.loadMore();
      final link = _model[Tag.letters].first;
      final article = await _model.article(link);

      expect(article.comments.length, equals(count));
    }

    test('single_page', () async => await _test('single_page', 30));
    test('triple_page', () async => await _test('triple_page', 40));
  });

  group('quotes count', () {
    Future _test(String name, int count) async {
      _mockFile(name);

      await _model.loadMore();
      final link = _model[Tag.letters].first;
      final article = await _model.article(link);
      final quotes = RegExp('class="quote"').allMatches(article.text);

      expect(quotes.length, equals(count));
    }

    test('single_page', () async => await _test('single_page', 52));
    test('triple_page', () async => await _test('triple_page', 88));
    test('with quotes', () async => await _test('quotes_with_quotes', 34));
    test('multiline_quotes', () async => await _test('multiline_quotes', 16));
  });

  group('expandable comments count', () {
    Future _test(String name, int count) async {
      _mockFile(name);

      await _model.loadMore();
      final link = _model[Tag.letters].first;
      final article = await _model.article(link);

      expect(_model.expandable(article.comments).length, equals(count));
    }

    test('single_page', () async => await _test('single_page', 5));
    test('triple_page', () async => await _test('triple_page', 7));
  });

  group('comments order on', () {
    Future _test(String name) async {
      _mockFile(name);

      await _model.loadMore();
      final link = _model[Tag.letters].first;
      final article = await _model.article(link);

      final actual = article.comments.map((e) => e.article).join("\n\n");
      if (_update) {
        await File(_path('order_$name.txt')).writeAsString(actual);
      } else {
        expect(actual, equals(await _asset('order_$name.txt')));
      }
    }

    test('single_page', () async => await _test('single_page'));
    test('triple_page', () async => await _test('triple_page'));
  });

  group('titles order', () {
    Future _test(Tag tag) async {
      _mockFile('single_page');

      await _model.loadMore();
      final actual = _model[tag].join("\n\n");
      final expected = await _asset('order_titles_$tag.txt');

      expect(actual, equals(expected));
    }

    test('any', () async => await _test(Tag.any));
    test('others', () async => await _test(Tag.others));
    test('letters', () async => await _test(Tag.letters));
  });
}

Future<String> _fromFile(_) {
  return Future.value(_files['page']);
}

void _mockFile(String id) {
  assert(_files.containsKey(id));
  when(_loader.body(any)).thenAnswer((_) => Future.value(_files[id]));
  when(_loader.body(argThat(contains('thread='))))
      .thenAnswer((_) => Future.value(_files['thread']));
}

String _path(String name) {
  return 'test/assets/$name';
}

Future<String> _asset(String name) {
  return File(_path(name)).readAsString();
}

String _baseAsset(String name) {
  return File(_path('evo-lutio.livejournal.com$name')).readAsStringSync();
}
