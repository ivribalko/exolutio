import 'dart:math';

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
import 'theme.dart';
import 'view_model.dart';

class Exolutio extends StatelessWidget {
  static final _messages = [
    'Здравствуйте,\nЭволюция!',
    'Здравствуйте,\nУважаемая Эволюция.',
    'Здравствуйте!',
    'Здравствуйте,\nЭволюция.',
    'Уважаемая Эволюция,\nдобрый день!',
    'Здравствуйте,\nдорогая Эволюция!',
  ];
  final _index = new Random().nextInt(_messages.length);

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
          theme: lightTheme(font),
          darkTheme: darkTheme(font),
          initialRoute: Routes.load,
          routes: {
            Routes.load: (context) => _buildSplashScreen(context),
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

  SplashScreen _buildSplashScreen(BuildContext context) {
    return SplashScreen(
      seconds: 2,
      title: Text(
        _messages[_index],
        textAlign: TextAlign.center,
        style: new TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: Theme.of(context).textTheme.headline3.fontSize,
        ),
      ),
      loaderColor: Theme.of(context).scaffoldBackgroundColor,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      navigateAfterSeconds: Routes.home,
    );
  }

  ChangeNotifierProvider<T> provide<T extends ChangeNotifier>() {
    return ChangeNotifierProvider<T>(create: (_) => locator<T>());
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
      child: HomeScreen(),
    );
  }
}
