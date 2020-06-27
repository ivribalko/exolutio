import 'dart:io';

import 'package:exolutio/src/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPreferences extends Mock implements SharedPreferences {}

void main() {
  test('comments count is 42', () {
    final html = File.fromUri(
      Uri.file('evo-lutio.livejournal.com_1185261.html'),
    );
    final model = Model(MockPreferences());
    final link = model[Tag.letters].first;
    final article = model.article(link) as Article;

    expect(42, article.comments.length);
  });
}
