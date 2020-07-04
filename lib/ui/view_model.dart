import 'package:exolutio/src/html_model.dart';
import 'package:exolutio/src/loader.dart';
import 'package:flutter/material.dart';

class HtmlViewModel extends HtmlModel with ChangeNotifier {
  HtmlViewModel(Loader loader) : super(loader);

  @override
  Future<List<Link>> loadMore() async {
    return super.loadMore().then((result) {
      notifyListeners();
      return result;
    });
  }
}
