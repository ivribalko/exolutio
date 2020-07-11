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
bool _rewrite = false;

void main() {
  setUp(() {
    _loader = MockLoader();
    when(_loader.page(any)).thenAnswer((_) => Future.value(_files['page']));
    _model = HtmlViewModel(_loader);
  });
  tearDown(() {
    _model.dispose();
  });

  test('first comment text', () async {
    _loadFile('single_page');

    await _model.loadMore();
    final link = _model[Tag.letters].first;
    final article = await _model.article(link);

    expect(
        article.comments[0].article,
        equals('Предыдущее письмо автора: <a href=\'https://evo-lutio.'
            'livejournal.com/903296.html\'>https://evo-lutio.livejournal.'
            'com/903296.html</a> '));
  });

  test('comments count on single_page', () async {
    _loadFile('single_page');

    await _model.loadMore();
    final link = _model[Tag.letters].first;
    final article = await _model.article(link);

    expect(article.comments.length, equals(30));
  });

  test('comments count on triple_page', () async {
    _loadFile('triple_page');

    await _model.loadMore();
    final link = _model[Tag.letters].first;
    final article = await _model.article(link);

    expect(article.comments.length, equals(40));
  });

  test('quotes count on single_page', () async {
    _loadFile('single_page');

    await _model.loadMore();
    final link = _model[Tag.letters].first;
    final article = await _model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(52));
  });

  test('quotes count on triple_page', () async {
    _loadFile('triple_page');

    await _model.loadMore();
    final link = _model[Tag.letters].first;
    final article = await _model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(88));
  });

  test('quotes count on multiline_quotes', () async {
    _loadFile('multiline_quotes');

    await _model.loadMore();
    final link = _model[Tag.letters].first;
    final article = await _model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(16));
  });

  test('quotes with quotes', () async {
    _loadFile('quotes_with_quotes');

    await _model.loadMore();
    final link = _model[Tag.letters].first;
    final article = await _model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(34));
  });

  test('expandable comments count single_page', () async {
    _loadFile('single_page');

    await _model.loadMore();
    final link = _model[Tag.letters].first;
    final article = await _model.article(link);

    expect(_model.expandable(article.comments).length, equals(5));
  });

  test('expandable comments count triple_page', () async {
    _loadFile('triple_page');

    await _model.loadMore();
    final link = _model[Tag.letters].first;
    final article = await _model.article(link);

    expect(_model.expandable(article.comments).length, equals(7));
  });

  test('comments order single_page', () async {
    _loadFile('single_page');

    await _model.loadMore();
    final link = _model[Tag.letters].first;
    final article = await _model.article(link);

    final actual = article.comments.map((e) => e.article).join("\n\n");
    if (_rewrite) {
      await File('test/assets/order_single_page.txt').writeAsString(actual);
    } else {
      final expected =
          await File('test/assets/order_single_page.txt').readAsString();

      expect(actual, equals(expected));
    }
  });

  test('comments order triple_page', () async {
    _loadFile('triple_page');

    await _model.loadMore();
    final link = _model[Tag.letters].first;
    final article = await _model.article(link);

    final actual = article.comments.map((e) => e.article).join("\n\n");
    if (_rewrite) {
      await File('test/assets/order_triple_page.txt').writeAsString(actual);
    } else {
      final expected =
          await File('test/assets/order_triple_page.txt').readAsString();

      expect(actual, equals(expected));
    }
  });

  test('titles order any', () async {
    await _testTitlesOrder(Tag.any);
  });

  test('titles order others', () async {
    await _testTitlesOrder(Tag.others);
  });

  test('titles order letters', () async {
    await _testTitlesOrder(Tag.letters);
  });
}

void _loadFile(String id) {
  assert(_files.containsKey(id));
  when(_loader.body(any)).thenAnswer((_) => Future.value(_files[id]));
  when(_loader.body(argThat(contains('thread='))))
      .thenAnswer((_) => Future.value(_files['thread']));
}

Future _testTitlesOrder(Tag tag) async {
  _loadFile('single_page');

  await _model.loadMore();
  final actual = _model[tag].join("\n\n");
  final expected =
      await File('test/assets/order_titles_$tag.txt').readAsString();

  expect(actual, equals(expected));
}
