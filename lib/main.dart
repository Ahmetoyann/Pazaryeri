import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'presentation/screens/Customer/home_screen.dart';
import 'presentation/screens/Customer/search_screen.dart';
import 'presentation/screens/Customer/report_list_screen.dart';
import 'presentation/screens/Customer/market_detail_screen.dart';
import 'presentation/screens/Customer/my_questions_screen.dart';
import 'presentation/screens/Customer/my_reviews_screen.dart';
import 'presentation/screens/Customer/products_screen.dart';
import 'presentation/screens/Customer/product_detail_screen.dart';
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
import 'core/constants/app_icons.dart';
import 'presentation/widgets/svg_icon.dart';
import 'presentation/widgets/side_menu_drawer.dart';
import 'presentation/widgets/loading_overlay.dart';

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
          final baseTheme = AppTheme.darkTheme(themeVM.seedColor);
          final modernTextTheme =
              GoogleFonts.interTextTheme(baseTheme.textTheme);
          final boldTheme = baseTheme.copyWith(
            textTheme: modernTextTheme,
          );

          // Modern Light Tema
          final lightBase = ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
              primary: Colors.orange,
              secondary: Colors.deepOrange,
              surface: Colors.white,
              onSurface: Colors.black87,
              surfaceContainer: Colors.orange.shade50,
            ),
            scaffoldBackgroundColor: Colors.white,
            cardTheme: CardThemeData(
              color: Colors.orange.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.orange.withOpacity(0.1)),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          );
          final lightTextTheme =
              GoogleFonts.interTextTheme(lightBase.textTheme);
          final finalLightTheme = lightBase.copyWith(
            textTheme: lightTextTheme,
          );

          return LifecycleManager(
            child: MaterialApp(
              navigatorKey: navigatorKey, // Key'i tanımla
              navigatorObservers: [KeyboardDismissObserver()],
              debugShowCheckedModeBanner: false,
              title: languageVM.translate('home_title'),
              themeMode: themeVM.themeMode,
              theme: finalLightTheme,
              darkTheme: boldTheme, // Merkezi Karanlık Tema
              themeAnimationDuration: const Duration(milliseconds: 500),
              themeAnimationCurve: Curves.easeInOut,
              locale: Locale(languageVM.currentLanguage),
              supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [Colors.black, Colors.black]
                                : [Colors.white, Colors.white],
                          ),
                        ),
                      ),
                    ),
                    if (child != null) GlobalConnectivityManager(child: child),
                  ],
                );
              },
              home: StartupConnectivityWrapper(
                onConnected: () => SplashScreen(
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
            ),
          );
        },
      ),
    );
  }
}

class StartupConnectivityWrapper extends StatefulWidget {
  final Widget Function() onConnected;

  const StartupConnectivityWrapper({super.key, required this.onConnected});

  @override
  State<StartupConnectivityWrapper> createState() =>
      _StartupConnectivityWrapperState();
}

class _StartupConnectivityWrapperState
    extends State<StartupConnectivityWrapper> {
  bool? _hasConnection;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final result = await Connectivity().checkConnectivity();
    final hasConnection = !result.contains(ConnectivityResult.none);

    if (mounted) {
      setState(() {
        _hasConnection = hasConnection;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasConnection == null) {
      // Kontrol sırasında şeffaf arka plan üzerinde loading (Arka plandaki gradient görünür)
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CustomLoadingIndicator()),
      );
    }

    if (_hasConnection == false) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 80, color: Colors.white70),
              const SizedBox(height: 20),
              const Text(
                'İnternet Bağlantısı Yok',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text('Lütfen bağlantınızı kontrol edin.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() => _hasConnection = null);
                  _checkConnection();
                },
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.onConnected();
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
        // İnternet geldiğinde son başarısız işlemi tekrar dene
        AuthService.instance.retryLastOperation();
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

    String message = 'Connection restored';
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
            duration: Duration.zero,
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
            authVM.checkFavoriteProductsPriceDrops(); // Fiyat düşüşü kontrolü
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
  bool _isDrawerOpen = false;

  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    ProductsScreen(),
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
        _handleNotificationNavigation(payload);
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

    _handleNotificationNavigation(marketId);
    NotificationService.instance.launchPayload = null;
  }

  void _handleNotificationNavigation(String payload) {
    // 0. Ürün Fiyat Düşüşü Bildirimi
    if (payload.startsWith('product_')) {
      final productId = payload.replaceFirst('product_', '');
      _navigateToProductDetail(productId);
      return;
    }

    // 1. Soru Yanıtı Bildirimi
    if (payload == 'question_reply') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const MyQuestionsScreen()),
      );
      return;
    }

    // 2. Değerlendirme Yanıtı Bildirimi
    if (payload == 'review_reply') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
      );
      return;
    }

    // 3. Pazar Bildirimi (Varsayılan olarak payload marketId kabul edilir)
    _navigateToMarketDetail(payload);
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

  Future<void> _navigateToProductDetail(String productId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (doc.exists) {
        final productData = doc.data()!;
        productData['id'] = doc.id;

        String sellerName = 'Satıcı';
        if (productData['sellerId'] != null) {
          final sellerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(productData['sellerId'])
              .get();
          if (sellerDoc.exists) {
            final sData = sellerDoc.data()!;
            sellerName = sData['stallName'] ??
                '${sData['firstName']} ${sData['lastName']}';
          }
        }

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: productData,
              sellerName: sellerName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Ürün detayına gidilemedi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
        extendBody: true,
        drawerScrimColor:
            Colors.black.withOpacity(0.6), // Arka plan karartma rengi
        onDrawerChanged: (isOpened) {
          setState(() {
            _isDrawerOpen = isOpened;
          });
        },
        drawer: const SideMenuDrawer(),
        body: Stack(
          children: [
            IndexedStack(index: _index, children: _screens),
            // Drawer açıkken arka planı bulanıklaştır
            if (_isDrawerOpen)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(color: Colors.transparent),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _isDrawerOpen
            ? null
            : Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                      ),
                      child: BottomNavigationBar(
                        currentIndex: _index,
                        onTap: (i) => setState(() => _index = i),
                        // Renkler ve stiller artık AppTheme içinden geliyor
                        // Ancak buradaki backgroundColor transparent olmalı çünkü
                        // üstteki Container blur efekti veriyor.
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        type: BottomNavigationBarType.fixed,
                        showSelectedLabels: true,
                        showUnselectedLabels: true,
                        selectedItemColor:
                            Theme.of(context).colorScheme.primary,
                        unselectedItemColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey
                                : Colors.grey,
                        unselectedFontSize: 8,
                        selectedFontSize: 10,
                        iconSize: 24,
                        items: [
                          BottomNavigationBarItem(
                            icon: Icon(
                              Icons.storefront_outlined,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey
                                  : Colors.grey,
                              size: 34,
                            ),
                            activeIcon: Icon(Icons.storefront,
                                color: Theme.of(context).colorScheme.primary,
                                size: 38),
                            label: langVM.translate('home_title'),
                          ),
                          BottomNavigationBarItem(
                            icon: SvgIcon(
                                iconPath: AppIcons.search,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey
                                    : Colors.grey,
                                size: 34),
                            activeIcon: SvgIcon(
                                iconPath: AppIcons.searchActive,
                                color: Theme.of(context).colorScheme.primary,
                                size: 38),
                            label: langVM.translate('search_tab'),
                          ),
                          BottomNavigationBarItem(
                            icon: SvgIcon(
                                iconPath: AppIcons.products,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey
                                    : Colors.grey,
                                size: 34),
                            activeIcon: SvgIcon(
                                iconPath: AppIcons.productsActive,
                                color: Theme.of(context).colorScheme.primary,
                                size: 38),
                            label: langVM.translate('products_tab'),
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(
                              Icons.report_outlined,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey
                                  : Colors.grey,
                              size: 34,
                            ),
                            activeIcon: Icon(
                              Icons.report,
                              color: Theme.of(context).colorScheme.primary,
                              size: 38,
                            ),
                            label: langVM.translate('report_tab'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ));
  }
}
