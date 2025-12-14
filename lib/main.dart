import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/screens/account_screen.dart';
import 'presentation/screens/report_list_screen.dart';
import 'presentation/viewmodels/home_viewmodel.dart';
import 'presentation/screens/auth_viewmodel.dart';
import 'presentation/screens/theme_viewmodel.dart';
import 'presentation/viewmodels/language_viewmodel.dart';
import 'core/location/geolocator_location_service.dart';
import 'data/repositories/market_repository.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/viewmodels/notification_service.dart';
import 'presentation/screens/auth_service.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/widgets/connectivity_wrapper.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  final bool showOnboarding = !(await AuthService.instance.isOnboardingSeen());
  runApp(MyApp(showOnboarding: showOnboarding));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    final locationService = GeolocatorLocationService();
    final marketRepository = FirestoreMarketRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageViewModel()),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(locationService, marketRepository),
        ),
      ],
      child: Consumer2<ThemeViewModel, LanguageViewModel>(
        builder: (context, themeVM, languageVM, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: languageVM.translate('home_title'),
            themeMode: themeVM.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeVM.seedColor,
                brightness:
                    themeVM.isDarkMode ? Brightness.dark : Brightness.light,
              ),
              useMaterial3: true,
            ),
            locale: Locale(languageVM.currentLanguage),
            supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: SplashScreen(
              nextScreen: showOnboarding
                  ? OnboardingScreen(
                      onDone: (ctx) => Navigator.of(ctx).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      ),
                    )
                  : const AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, child) {
        final bool isLoggedIn = authVM.isAuthenticated || authVM.isGuest;
        final screen = isLoggedIn
            ? const _HomeWrapper(key: ValueKey('HomeWrapper'))
            : LoginScreen(
                key: const ValueKey('LoginScreen'),
                onLoginSuccess: () {
                  Provider.of<HomeViewModel>(context, listen: false).loadData();
                },
              );

        return ConnectivityWrapper(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: screen,
          ),
        );
      },
    );
  }
}

class _HomeWrapper extends StatefulWidget {
  const _HomeWrapper({Key? key}) : super(key: key);

  @override
  State<_HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<_HomeWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<HomeViewModel>(context, listen: false);
      if (vm.nearbyMarkets.isEmpty && vm.state == ViewState.idle) {
        vm.loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainScaffold();
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    AccountScreen(),
    ReportListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home),
                    label: langVM.translate('home_title'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.search_outlined),
                    activeIcon: const Icon(Icons.search),
                    label: langVM.translate('search_tab'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline),
                    activeIcon: const Icon(Icons.person),
                    label: langVM.translate('account_title'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.report_gmailerrorred_outlined),
                    activeIcon: const Icon(Icons.report),
                    label: langVM.translate('report_tab'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
