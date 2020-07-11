import 'package:get_it/get_it.dart';
import 'package:shared/loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/firebase.dart';
import 'src/meta_model.dart';
import 'ui/view_model.dart';

GetIt locator = GetIt.instance;

Future<void> setUp() async {
  final prefs = await SharedPreferences.getInstance();

  locator.registerSingleton(HtmlViewModel(Loader()));
  locator.registerSingleton(MetaModel(prefs));
  locator.registerSingleton(Firebase());
}
