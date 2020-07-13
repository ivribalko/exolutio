import 'package:client/src/meta_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splashscreen/splashscreen.dart';

import '../locator.dart';
import 'deeplink.dart';
import 'home/screen.dart';
import 'messages.dart';
import 'read/screen.dart';
import 'routes.dart';
import 'view_model.dart';

class Exolutio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        provide<HtmlViewModel>(),
        provide<MetaModel>(),
      ],
      child: Selector<MetaModel, String>(
        selector: (_, model) => model.font,
        builder: (_, font, __) => MaterialApp(
          title: 'Exolutio',
          theme: _buildLightTheme(font),
          darkTheme: _buildDarkTheme(font),
          initialRoute: Routes.home,
          routes: {
            Routes.home: (context) => _multiProviderHome(context),
            Routes.read: (context) => ReadScreen(context),
          },
          // https://github.com/Sub6Resources/flutter_html/issues/294#issuecomment-637318948
          builder: (BuildContext context, Widget child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
            child: child,
          ),
        ),
      ),
    );
  }

  ChangeNotifierProvider<T> provide<T extends ChangeNotifier>() {
    return ChangeNotifierProvider<T>(create: (_) => locator<T>());
  }

  ThemeData _buildLightTheme(String font) {
    return ThemeData(
      primaryColor: Color.fromRGBO(1, 67, 89, 1),
      accentColor: Color.fromRGBO(1, 67, 89, 1),
      highlightColor: Color.fromRGBO(1, 67, 89, 1),
      brightness: Brightness.light,
      fontFamily: font,
    );
  }

  ThemeData _buildDarkTheme(String font) {
    return ThemeData(
      primaryColor: Colors.black,
      cardColor: Colors.white10,
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      bottomAppBarColor: Colors.black,
      backgroundColor: Colors.black,
      brightness: Brightness.dark,
      fontFamily: font,
    );
  }

  Widget _multiProviderHome(context) {
    return MultiProvider(
      providers: [
        Provider<DeepRouter>(
          create: (context) => DeepRouter(context),
          lazy: false,
        ),
        Provider<PushRouter>(
          create: (context) => PushRouter(context),
          lazy: false,
        ),
      ],
      child: SplashScreen(
        seconds: 2,
        title: Text(
          'Здравствуйте,\nЭволюция!',
          textAlign: TextAlign.center,
          style: new TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Theme.of(context).textTheme.headline3.fontSize,
          ),
        ),
        loaderColor: Theme.of(context).backgroundColor,
        backgroundColor: Theme.of(context).backgroundColor,
        navigateAfterSeconds: HomeScreen(),
      ),
    );
  }
}
