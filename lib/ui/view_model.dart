import 'package:exolutio/src/html_model.dart';
import 'package:exolutio/src/loader.dart';
import 'package:flutter/material.dart';

class HtmlViewModel extends HtmlModel with ChangeNotifier {
  HtmlViewModel(Loader loader) : super(loader);

  @override
  Future loadMore() async {
    return super.loadMore().then((_) => notifyListeners());
  }
}
