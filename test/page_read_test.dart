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
          'test/evo-lutio.livejournal.com__1180335_thread=87311791.html',
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
    loadFile('1180335');

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

  test('comments count on 1180335', () async {
    loadFile('1180335');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(article.comments.length, equals(22));
  });

  test('comments count on 1179434', () async {
    loadFile('1179434');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(article.comments.length, equals(54));
  });

  test('quotes count on 1180335', () async {
    loadFile('1180335');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(52));
  });

  test('quotes count on 1179434', () async {
    loadFile('1179434');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);
    final quotes = RegExp('class="quote"').allMatches(article.text);

    expect(quotes.length, equals(60));
  });

  test('expandable comments count', () async {
    loadFile('1180335');

    model.loadMore();
    await updated.stream.first;
    final link = model[Tag.letters].first;
    final article = await model.article(link);

    expect(model.expandable(article.comments).length, equals(5));
  });
}
