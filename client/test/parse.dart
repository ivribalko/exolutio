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
  'page': File(
    'test/assets/evo-lutio.livejournal.com.htm',
  ).readAsStringSync(),
  'thread': File(
    'test/assets/evo-lutio.livejournal.com__single_page_thread=add_two.htm',
  ).readAsStringSync(),
  'single_page': File(
    'test/assets/evo-lutio.livejournal.com__single_page.htm',
  ).readAsStringSync(),
  'triple_page': File(
    'test/assets/evo-lutio.livejournal.com__triple_page.htm',
  ).readAsStringSync(),
  'quotes_with_quotes': File(
    'test/assets/evo-lutio.livejournal.com__quotes_with_quotes.htm',
  ).readAsStringSync(),
  'multiline_quotes': File(
    'test/assets/evo-lutio.livejournal.com__multiline_quotes.htm',
  ).readAsStringSync(),
};

Loader _loader;
HtmlViewModel _model;
bool _update = false;

void main() {
  setUp(() {
    _loader = MockLoader();
    when(_loader.page(any)).thenAnswer((_) => Future.value(_files['page']));
    _model = HtmlViewModel(_loader);
  });
  tearDown(() {
    _model.dispose();
  });

  group('comments count on ', () {
    Future _test(String name, int count) async {
      _loadFile(name);

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
      _loadFile(name);

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
      _loadFile(name);

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
      _loadFile(name);

      await _model.loadMore();
      final link = _model[Tag.letters].first;
      final article = await _model.article(link);

      final actual = article.comments.map((e) => e.article).join("\n\n");
      if (_update) {
        await File('test/assets/order_$name.txt').writeAsString(actual);
      } else {
        final expected =
            await File('test/assets/order_$name.txt').readAsString();

        expect(actual, equals(expected));
      }
    }

    test('single_page', () async => await _test('single_page'));
    test('triple_page', () async => await _test('triple_page'));
  });

  group('titles order', () {
    Future _test(Tag tag) async {
      _loadFile('single_page');

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

void _loadFile(String id) {
  assert(_files.containsKey(id));
  when(_loader.body(any)).thenAnswer((_) => Future.value(_files[id]));
  when(_loader.body(argThat(contains('thread='))))
      .thenAnswer((_) => Future.value(_files['thread']));
}

String _path(String name) => 'test/assets/$name';

Future<String> _asset(String name) {
  return File(_path(name)).readAsString();
}
