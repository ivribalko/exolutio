import 'package:flutter/material.dart';
import 'package:shared/html_model.dart';
import 'package:shared/loader.dart';

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
