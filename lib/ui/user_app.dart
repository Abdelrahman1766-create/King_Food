import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;

import '../providers/address_provider.dart';
import '../providers/language_provider.dart';
import 'app_shell.dart';

class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(
          create: (context) => LanguageProvider(),
        ),
        provider.ChangeNotifierProvider(
          create: (context) => AddressProvider(),
        ),
      ],
      child: provider.Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'King Food',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.locale,
            supportedLocales: LanguageProvider.supportedLocales,
            localizationsDelegates: LanguageProvider.localizationsDelegates,
            scrollBehavior: const _AppScrollBehavior(),
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
              useMaterial3: true,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
                  TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
                  TargetPlatform.macOS: _FadeSlidePageTransitionsBuilder(),
                  TargetPlatform.windows: _FadeSlidePageTransitionsBuilder(),
                  TargetPlatform.linux: _FadeSlidePageTransitionsBuilder(),
                },
              ),
            ),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.settings.name == Navigator.defaultRouteName) {
      return child;
    }

    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final slideTween = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: slideTween, child: child),
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}
