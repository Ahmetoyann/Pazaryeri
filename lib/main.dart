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
import 'presentation/screens/Customer/market_detail_screen.dart';
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
import 'app_theme.dart';
import 'presentation/widgets/success_dialog.dart';

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
              themeMode: themeVM.themeMode, // Tema modu (Sistem/Açık/Koyu)
              theme: AppTheme.lightTheme(
                  themeVM.seedColor), // Merkezi Aydınlık Tema
              darkTheme: AppTheme.darkTheme(
                  themeVM.seedColor), // Merkezi Karanlık Tema
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
                                    const Color(0xFF1B5E20), // Sabit koyu yeşil
                                    const Color.fromRGBO(27, 94, 32, 1),
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
                                .withOpacity(isDark ? 0.4 : 0.0),
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
                            color: theme.colorScheme.tertiary
                                .withOpacity(isDark ? 0.4 : 0.0),
                          ),
                        ),
                      ),
                    ),
                    if (child != null) GlobalConnectivityManager(child: child),
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

class GlobalConnectivityManager extends StatefulWidget {
  final Widget child;
  const GlobalConnectivityManager({super.key, required this.child});

  @override
  State<GlobalConnectivityManager> createState() =>
      _GlobalConnectivityManagerState();
}

class _GlobalConnectivityManagerState extends State<GlobalConnectivityManager> {
  StreamSubscription? _subscription;
  bool _isDialogShowing = false;
  bool _wasDisconnected = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      final bool hasConnection = !result.contains(ConnectivityResult.none);
      if (!hasConnection) {
        _wasDisconnected = true;
        _showNoInternetDialog();
      } else if (_wasDisconnected) {
        _wasDisconnected = false;
        _showConnectionRestoredDialog();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _showNoInternetDialog() async {
    if (_isDialogShowing) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    _isDialogShowing = true;

    // Dil desteği için güvenli erişim
    String message = 'İnternet bağlantısı yok';
    try {
      final langVM = Provider.of<LanguageViewModel>(context, listen: false);
      message = langVM.translate('no_internet');
    } catch (_) {}

    await DialogService.showError(
      context,
      message: message,
    );

    if (mounted) {
      _isDialogShowing = false;
    }
  }

  Future<void> _showConnectionRestoredDialog() async {
    // Eğer şu an "İnternet yok" diyaloğu açıksa kapanmasını bekle
    while (_isDialogShowing) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;

    _isDialogShowing = true;

    String message = 'Bağlantı sağlandı';
    try {
      final langVM = Provider.of<LanguageViewModel>(context, listen: false);
      final translated = langVM.translate('connection_restored');
      if (translated != 'connection_restored') {
        message = translated;
      }
    } catch (_) {}

    await DialogService.showSuccess(
      context,
      message: message,
    );

    if (mounted) {
      _isDialogShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
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
        vm.loadData().then((_) {
          // Veriler yüklendikten sonra favori kontrolü yap
          if (mounted) {
            final authVM = Provider.of<AuthViewModel>(context, listen: false);
            authVM.checkFavoritesAndNotify(vm.nearbyMarkets);
          }
        });
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
        _handleNotificationLaunch(initialPayload);
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

  Future<void> _handleNotificationLaunch(String marketId) async {
    final homeVM = Provider.of<HomeViewModel>(context, listen: false);

    // Eğer uygulama soğuk açılış yaptıysa veriler henüz yüklenmemiş olabilir.
    // Yönlendirme yapmadan önce verilerin yüklenmesini bekliyoruz.
    if (homeVM.nearbyMarkets.isEmpty && homeVM.provinceMarkets.isEmpty) {
      await homeVM.loadData();
    }

    _navigateToMarketDetail(marketId);
    NotificationService.instance.launchPayload = null;
  }

  Widget _buildActiveIcon(BuildContext context, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Icon(icon, size: 30),
    );
  }

  void _navigateToMarketDetail(String marketId) {
    final homeVM = Provider.of<HomeViewModel>(context, listen: false);

    // Hem yakındaki hem de il bazlı pazarlarda arama yap
    try {
      final market = homeVM.nearbyMarkets.firstWhere((m) => m.id == marketId,
          orElse: () =>
              homeVM.provinceMarkets.firstWhere((m) => m.id == marketId));

      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => MarketDetailScreen(market: market)),
      );
    } catch (e) {
      debugPrint('Bildirimden gelen pazar ID bulunamadı: $marketId');
      // İsteğe bağlı: Pazar bulunamazsa kullanıcıya bilgi verilebilir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pazar detayları yüklenemedi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 32, right: 32, bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                // Renkler ve stiller artık AppTheme içinden geliyor
                // Ancak buradaki backgroundColor transparent olmalı çünkü
                // üstteki Container blur efekti veriyor.
                backgroundColor: Colors.transparent,
                elevation: 0,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                selectedFontSize: 3,
                unselectedFontSize: 0,
                iconSize: 30,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: _buildActiveIcon(context, Icons.home),
                    label: langVM.translate('home_title'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.search_outlined),
                    activeIcon: _buildActiveIcon(context, Icons.search),
                    label: langVM.translate('search_tab'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline),
                    activeIcon: _buildActiveIcon(context, Icons.person),
                    label: langVM.translate('account_title'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.report_gmailerrorred_outlined),
                    activeIcon: _buildActiveIcon(context, Icons.report),
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
