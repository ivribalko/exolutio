import 'dart:async';
import 'dart:io';

import 'package:exolutio/src/html_model.dart';
import 'package:exolutio/src/loader.dart';
import 'package:exolutio/ui/view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLoader extends Mock implements Loader {}

class MockPreferences extends Mock implements SharedPreferences {}

final files = <String, String>{
  'page': File(
    'test/evo-lutio.livejournal.com.htm',
  ).readAsStringSync(),
  'thread': File(
    'test/evo-lutio.livejournal.com__single_page_thread=add_two.htm',
  ).readAsStringSync(),
  'single_page': File(
    'test/evo-lutio.livejournal.com__single_page.htm',
  ).readAsStringSync(),
  'triple_page': File(
    'test/evo-lutio.livejournal.com__triple_page.htm',
  ).readAsStringSync(),
  'quotes_with_quotes': File(
    'test/evo-lutio.livejournal.com__quotes_with_quotes.htm',
  ).readAsStringSync(),
  'multiline_quotes': File(
    'test/evo-lutio.livejournal.com__multiline_quotes.htm',
  ).readAsStringSync(),
};

void main() {
  Loader loader;
  HtmlViewModel model;
  bool rewrite = false;

  void loadFile(String id) {
    assert(files.containsKey(id));
    when(loader.body(any)).thenAnswer((_) => Future.value(files[id]));
    when(loader.body(argThat(contains('thread='))))
        .thenAnswer((_) => Future.value(files['thread']));
  }

  setUp(() {
    loader = MockLoader();
    when(loader.page(any)).thenAnswer((_) => Future.value(files['page']));
    model = HtmlViewModel(loader);
  });
  tearDown(() {
    model.dispose();
  });

  test('first comment text', () async {
    loadFile('single_page');

    await model.loadMore();
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(
        article.comments[0].article,
        equals('Предыдущее письмо автора: <a href=\'https://evo-lutio.'
            'livejournal.com/903296.html\'>https://evo-lutio.livejournal.'
            'com/903296.html</a> '));
  });

  test('comments count on single_page', () async {
    loadFile('single_page');

    await model.loadMore();
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(article.comments.length, equals(30));
  });

  test('comments count on triple_page', () async {
    loadFile('triple_page');

    await model.loadMore();
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(article.comments.length, equals(40));
  });

  test('quotes count on single_page', () async {
    loadFile('single_page');

    await model.loadMore();
    final link = model[Tag.letters].first;
    final article = await model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(52));
  });

  test('quotes count on triple_page', () async {
    loadFile('triple_page');

    await model.loadMore();
    final link = model[Tag.letters].first;
    final article = await model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(88));
  });

  test('quotes count on multiline_quotes', () async {
    loadFile('multiline_quotes');

    await model.loadMore();
    final link = model[Tag.letters].first;
    final article = await model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(16));
  });

  test('expandable comments count single_page', () async {
    loadFile('single_page');

    await model.loadMore();
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(model.expandable(article.comments).length, equals(5));
  });

  test('expandable comments count triple_page', () async {
    loadFile('triple_page');

    await model.loadMore();
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(model.expandable(article.comments).length, equals(7));
  });

  test('comments order single_page', () async {
    loadFile('single_page');

    await model.loadMore();
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    final actual = article.comments.map((e) => e.article).join("\n\n");
    if (rewrite) {
      await File('test/order_single_page.txt').writeAsString(actual);
    } else {
      final expected = await File('test/order_single_page.txt').readAsString();

      expect(actual, equals(expected));
    }
  });

  test('comments order triple_page', () async {
    loadFile('triple_page');

    await model.loadMore();
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    final actual = article.comments.map((e) => e.article).join("\n\n");
    if (rewrite) {
      await File('test/order_triple_page.txt').writeAsString(actual);
    } else {
      final expected = await File('test/order_triple_page.txt').readAsString();

      expect(actual, equals(expected));
    }
  });

  Future testTitlesOrder(Tag tag) async {
    loadFile('single_page');

    await model.loadMore();
    final actual = model[tag].join("\n\n");
    final expected = await File('test/order_titles_$tag.txt').readAsString();

    expect(actual, equals(expected));
  }

  test('titles order any', () async {
    await testTitlesOrder(Tag.any);
  });

  test('titles order others', () async {
    await testTitlesOrder(Tag.others);
  });

  test('titles order letters', () async {
    await testTitlesOrder(Tag.letters);
  });

  test('quotes with quotes', () async {
    loadFile('quotes_with_quotes');

    await model.loadMore();
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(article.comments.length, equals(23));
  });
}
