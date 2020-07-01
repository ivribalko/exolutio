import 'dart:async';
import 'dart:io';

import 'package:exolutio/src/loader.dart';
import 'package:exolutio/src/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLoader extends Mock implements Loader {}

class MockPreferences extends Mock implements SharedPreferences {}

void main() {
  Model model;
  Loader loader;
  StreamController updated;

  void loadFile(String id) {
    when(loader.body(any)).thenAnswer((_) => File(
          'test/evo-lutio.livejournal.com__$id.html',
        ).readAsString());

    when(loader.body(argThat(contains('thread=')))).thenAnswer((_) => File(
          'test/evo-lutio.livejournal.com__single_page_thread=add_two.html',
        ).readAsString());
  }

  setUp(() {
    loader = MockLoader();

    when(loader.page(any)).thenAnswer((_) => File(
          'test/evo-lutio.livejournal.com.html',
        ).readAsString());

    updated = StreamController();
    model = Model(loader, MockPreferences());
    model.addListener(() => updated.add(null));
  });
  tearDown(() {
    updated.close();
    model.dispose();
  });

  test('first comment text', () async {
    loadFile('single_page');

    model.loadMore();
    await updated.stream.first;
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

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(article.comments.length, equals(30));
  });

  test('comments count on double_page', () async {
    loadFile('double_page');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(article.comments.length, equals(74));
  });

  test('comments count on triple_page', () async {
    loadFile('triple_page');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(article.comments.length, equals(40));
  });

  test('quotes count on single_page', () async {
    loadFile('single_page');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(52));
  });

  test('quotes count on double_page', () async {
    loadFile('double_page');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(60));
  });

  test('quotes count on triple_page', () async {
    loadFile('triple_page');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(72));
  });

  test('expandable comments count single_page', () async {
    loadFile('single_page');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(model.expandable(article.comments).length, equals(5));
  });

  test('expandable comments count triple_page', () async {
    loadFile('triple_page');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(model.expandable(article.comments).length, equals(7));
  });

  test('comments order single_page', () async {
    loadFile('single_page');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    final actual = article.comments.map((e) => e.article).join("\n\n");
    final expected = await File('test/order_single_page.txt').readAsString();

    expect(actual, equals(expected));
  });

  test('comments order triple_page', () async {
    loadFile('triple_page');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    final actual = article.comments.map((e) => e.article).join("\n\n");
    final expected = await File('test/order_triple_page.txt').readAsString();

    expect(actual, equals(expected));
  });
}
