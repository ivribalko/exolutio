import 'dart:io';

import 'package:exolutio/src/html_model.dart';
import 'package:exolutio/src/loader.dart';

void main() async {
  final model = HtmlModel(Loader());
  await model.loadMore();
  print(model[Tag.letters].map((e) => e.title).join('\n'));
  exit(0);
}
