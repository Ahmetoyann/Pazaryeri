import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'presentation/screens/Customer/home_screen.dart';
import 'presentation/screens/Customer/search_screen.dart';
import 'presentation/screens/Customer/account_screen.dart';
import 'presentation/screens/Customer/report_list_screen.dart';
import 'presentation/viewmodels/home_viewmodel.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'presentation/viewmodels/language_viewmodel.dart';
import 'presentation/viewmodels/seller_viewmodel.dart';
import 'core/location/geolocator_location_service.dart';
import 'data/repositories/market_repository.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/viewmodels/notification_service.dart';
import 'presentation/viewmodels/auth_service.dart';
import 'presentation/screens/Customer/onboarding_screen.dart';
import 'presentation/widgets/connectivity_wrapper.dart';
import 'presentation/screens/user_type_selection_screen.dart';
import 'presentation/screens/Seller/seller_market_selection_screen.dart';
import 'presentation/screens/Seller/seller_main_screen.dart';

// Global navigasyon anahtarı
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    final marketRepository =
        JsonMarketRepository(assetPath: 'assets/data/markets.json');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageViewModel()),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(locationService, marketRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SellerViewModel(marketRepository),
        ),
      ],
      child: Consumer3<ThemeViewModel, LanguageViewModel, AuthViewModel>(
        builder: (context, themeVM, languageVM, authVM, child) {
          return LifecycleManager(
            child: MaterialApp(
              navigatorKey: navigatorKey, // Key'i tanımla
              navigatorObservers: [KeyboardDismissObserver()],
              debugShowCheckedModeBanner: false,
              title: languageVM.translate('home_title'),
              themeMode: themeVM.themeMode,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: themeVM.seedColor,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
                scaffoldBackgroundColor: Colors.transparent,
                cardColor: Colors.white.withOpacity(0.9),
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: CustomScaleTransitionBuilder(),
                    TargetPlatform.iOS: CustomScaleTransitionBuilder(),
                  },
                ),
                chipTheme: ChipThemeData(
                  backgroundColor: Colors.white.withOpacity(0.5),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeVM.seedColor.withOpacity(0.85),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(), // Hap şeklinde buton
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeVM.seedColor,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    side: BorderSide(color: themeVM.seedColor.withOpacity(0.7)),
                    shape: const StadiumBorder(), // Hap şeklinde buton
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: themeVM.seedColor,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        BorderSide(color: themeVM.seedColor, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                textTheme: _buildTextTheme(
                    ThemeData.light().textTheme, Colors.black.withOpacity(0.2)),
                iconTheme: IconThemeData(
                  shadows: [
                    Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.2))
                  ],
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: themeVM.seedColor,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
                scaffoldBackgroundColor: Colors.transparent,
                cardColor: Colors.black.withOpacity(0.8),
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: CustomScaleTransitionBuilder(),
                    TargetPlatform.iOS: CustomScaleTransitionBuilder(),
                  },
                ),
                chipTheme: ChipThemeData(
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeVM.seedColor.withOpacity(0.85),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(), // Hap şeklinde buton
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeVM.seedColor,
                    backgroundColor: Colors.black.withOpacity(0.3),
                    side: BorderSide(color: themeVM.seedColor.withOpacity(0.7)),
                    shape: const StadiumBorder(), // Hap şeklinde buton
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: themeVM.seedColor,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        BorderSide(color: themeVM.seedColor, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                textTheme: _buildTextTheme(
                    ThemeData.dark().textTheme, Colors.black.withOpacity(0.5)),
                iconTheme: IconThemeData(
                  shadows: [
                    Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.5))
                  ],
                ),
              ),
              locale: Locale(languageVM.currentLanguage),
              supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF121212), // Koyu gri
                                    Colors.black,
                                  ]
                                : [
                                    theme.colorScheme.primary.withOpacity(0.05),
                                    const Color(0xFFFAFAFA), // Kırık beyaz
                                  ],
                          ),
                        ),
                      ),
                    ),
                    // Modern ve yumuşak bir arka plan efekti için bulanık daireler
                    Positioned(
                      top: -100,
                      right: -100,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary
                                .withOpacity(isDark ? 0.15 : 0.08),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: -50,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.secondary
                                .withOpacity(isDark ? 0.15 : 0.08),
                          ),
                        ),
                      ),
                    ),
                    if (child != null) child,
                  ],
                );
              },
              home: SplashScreen(
                nextScreen: showOnboarding
                    ? OnboardingScreen(
                        onDone: (ctx) => Navigator.of(ctx).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const AuthWrapper()),
                        ),
                      )
                    : const AuthWrapper(),
              ),
            ),
          );
        },
      ),
    );
  }
}

TextTheme _buildTextTheme(TextTheme base, Color shadowColor) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      shadows: [
        Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
      ],
    ),
    displayMedium: base.displayMedium?.copyWith(
      shadows: [
        Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
      ],
    ),
    displaySmall: base.displaySmall?.copyWith(
      shadows: [
        Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
      ],
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      shadows: [
        Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
      ],
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      shadows: [
        Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
      ],
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      shadows: [
        Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
      ],
    ),
    titleLarge: base.titleLarge?.copyWith(
      shadows: [
        Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
      ],
    ),
    titleMedium: base.titleMedium?.copyWith(
      shadows: [
        Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
      ],
    ),
    titleSmall: base.titleSmall?.copyWith(
      shadows: [
        Shadow(offset: const Offset(1, 1), blurRadius: 2, color: shadowColor)
      ],
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      shadows: [
        Shadow(
            offset: const Offset(0.5, 0.5), blurRadius: 1, color: shadowColor)
      ],
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      shadows: [
        Shadow(
            offset: const Offset(0.5, 0.5), blurRadius: 1, color: shadowColor)
      ],
    ),
    bodySmall: base.bodySmall?.copyWith(
      shadows: [
        Shadow(
            offset: const Offset(0.5, 0.5), blurRadius: 1, color: shadowColor)
      ],
    ),
    labelLarge: base.labelLarge?.copyWith(
      shadows: [
        Shadow(
            offset: const Offset(0.5, 0.5), blurRadius: 1, color: shadowColor)
      ],
    ),
  );
}

class CustomScaleTransitionBuilder extends PageTransitionsBuilder {
  const CustomScaleTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

class KeyboardDismissObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

class LifecycleManager extends StatefulWidget {
  final Widget child;
  const LifecycleManager({super.key, required this.child});

  @override
  State<LifecycleManager> createState() => _LifecycleManagerState();
}

class _LifecycleManagerState extends State<LifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, child) {
        final bool isLoggedIn = authVM.isAuthenticated || authVM.isGuest;

        Widget screen;
        if (isLoggedIn) {
          if (authVM.isSeller) {
            if (authVM.sellerMarketId != null &&
                authVM.sellerMarketId!.isNotEmpty) {
              screen =
                  const SellerMainScreen(key: ValueKey('SellerMainScreen'));
            } else {
              screen = const SellerMarketSelectionScreen(
                  key: ValueKey('SellerPanel'));
            }
          } else {
            screen = const _HomeWrapper(key: ValueKey('HomeWrapper'));
          }
        } else {
          screen = UserTypeSelectionScreen(
            key: const ValueKey('UserTypeSelection'),
            onLoginSuccess: () {
              Provider.of<HomeViewModel>(context, listen: false).loadData();
            },
          );
        }

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
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    // İnternet bağlantısı geri geldiğinde verileri yenile
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      // connectivity_plus 6.0+ sürümü her zaman List<ConnectivityResult> döndürür
      final bool hasConnection = !result.contains(ConnectivityResult.none);

      if (hasConnection) {
        // 1. Profil bilgilerini yenile (İsim, Fotoğraf, Favoriler vb.)
        Provider.of<AuthViewModel>(context, listen: false).refreshCurrentUser();

        // 2. Pazar verilerini yenile (Eğer daha önce yüklenemediyse)
        final homeVM = Provider.of<HomeViewModel>(context, listen: false);
        if (homeVM.nearbyMarkets.isEmpty) {
          homeVM.loadData();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<HomeViewModel>(context, listen: false);
      if (vm.nearbyMarkets.isEmpty && vm.state == ViewState.idle) {
        vm.loadData();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
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
  void initState() {
    super.initState();

    // Uygulama kapalıyken gelen bildirim kontrolü (Terminated State)
    final String? initialPayload = NotificationService.instance.launchPayload;
    if (initialPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToMarketDetail(initialPayload);
        NotificationService.instance.launchPayload =
            null; // Tekrar tetiklenmemesi için temizle
      });
    }

    // Bildirim tıklamalarını dinle
    NotificationService.instance.selectNotificationStream.stream
        .listen((payload) {
      if (payload != null && payload.isNotEmpty) {
        _navigateToMarketDetail(payload);
      }
    });
  }

  void _navigateToMarketDetail(String marketId) {
    // 1. HomeViewModel üzerinden pazarı bulmaya çalış
    final homeVM = Provider.of<HomeViewModel>(context, listen: false);

    // Not: Eğer pazar listesi henüz yüklenmediyse önce yüklemeyi deneyebilirsiniz
    // veya direkt ID ile MarketDetailScreen'e gidebilirsiniz.

    // ÖRNEK YÖNLENDİRME KODU:
    // MarketDetailScreen'in projenizde import edildiğinden emin olun.
    /*
    final market = homeVM.nearbyMarkets.firstWhere(
      (m) => m.id == marketId, 
      orElse: () => null
    );

    if (market != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => MarketDetailScreen(market: market)),
      );
    }
    */

    // Eğer MarketDetailScreen sadece ID alabiliyorsa:
    // navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => MarketDetailScreen(marketId: marketId)));

    debugPrint('Bildirime tıklandı, gidilecek pazar ID: $marketId');
  }

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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.white.withOpacity(0.2),
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
