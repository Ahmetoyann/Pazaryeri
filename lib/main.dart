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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';
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
import 'presentation/widgets/custom_snackbars.dart';
import 'core/constants/app_icons.dart';
import 'presentation/widgets/svg_icon.dart';
import 'presentation/widgets/side_menu_drawer.dart';
import 'presentation/widgets/loading_overlay.dart';
import 'firebase_options.dart';

// Global navigasyon anahtarı
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulamayı kenardan kenara (Edge-to-Edge) çizer. Durum çubuğu ve navigasyon çubuğu hep görünür ve arka planla bütünleşir.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Durum çubuğu (Status Bar) ve Navigasyon çubuğunun arka planını tamamen şeffaf yapar.
  // Böylece uygulama arka planı (Scaffold veya Gradient) üst çubuğun altından da kusursuzca görünür.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Arka plan bildirimlerini işlemek için handler'ı kaydet
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
            scaffoldBackgroundColor:
                const Color(0xFF161616), // Göz yormayan yumuşak siyah
            canvasColor: const Color(0xFF161616),
            appBarTheme: baseTheme.appBarTheme.copyWith(
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarColor: Color(0xFF161616),
                systemNavigationBarIconBrightness: Brightness.light,
              ),
            ),
          );

          // Modern Light Tema
          final lightColorScheme = ColorScheme.fromSeed(
            seedColor: themeVM.seedColor,
            primary: themeVM.seedColor,
            brightness: Brightness.light,
            surface: Colors.white,
          );
          final lightBase = ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: lightColorScheme,
            scaffoldBackgroundColor: Colors.white,
            cardTheme: CardThemeData(
              color: lightColorScheme.surfaceContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: lightColorScheme.primary.withOpacity(0.1)),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: lightColorScheme.onSurface),
              titleTextStyle: TextStyle(
                color: lightColorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: lightColorScheme.surfaceContainer,
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
                final overlayStyle = SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                  systemNavigationBarColor:
                      isDark ? const Color(0xFF161616) : Colors.white,
                  systemNavigationBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                );
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: overlayStyle,
                  child: Stack(
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
                                  ? [
                                      const Color(0xFF161616),
                                      const Color(0xFF161616)
                                    ] // Daha göz yormayan yumuşak siyah
                                  : [Colors.white, Colors.white],
                            ),
                          ),
                        ),
                      ),
                      if (child != null)
                        GlobalConnectivityManager(child: child),
                    ],
                  ),
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
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final result = await Connectivity().checkConnectivity();
    final hasConnection = !result.contains(ConnectivityResult.none);

    // Yeniden dene butonuna basıldığında ve internet hala yoksa,
    // spinner animasyonunun çok hızlı yanıp sönmesini engellemek için ufak bir gecikme:
    if (_isRetrying && !hasConnection) {
      await Future.delayed(const Duration(milliseconds: 600));
    }

    if (mounted) {
      setState(() {
        _hasConnection = hasConnection;
        _isRetrying = false;
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
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer
                        .withOpacity(isDark ? 0.2 : 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'İnternet Bağlantısı Yok',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pazaryeri\'ne erişebilmek için lütfen internet bağlantınızı kontrol edin.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: () {
                    if (_isRetrying) return;
                    setState(() => _isRetrying = true);
                    _checkConnection();
                  },
                  icon: _isRetrying
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                    _isRetrying ? 'Kontrol ediliyor...' : 'Yeniden Dene',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    AppSettings.openAppSettings(type: AppSettingsType.wifi);
                  },
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('WiFi Ayarlarına Git'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.7),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
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

    showDialog(
      context: context,
      barrierDismissible: false, // Dışarı tıklanarak kapatılmasını engeller
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        String message = 'İnternet bağlantısı yok';
        try {
          final langVM = Provider.of<LanguageViewModel>(context, listen: false);
          message = langVM.translate('no_internet');
        } catch (_) {}

        return PopScope(
          canPop:
              false, // Geri tuşu (Android) veya kaydırma (iOS) ile kapatılmasını engeller
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: 8, sigmaY: 8), // Arka planı bulanıklaştırır
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer
                            .withOpacity(isDark ? 0.2 : 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bağlantınız koptu. Lütfen internet ayarlarınızı kontrol edin. Sistem bağlantıyı otomatik olarak bekliyor...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () {
                        AppSettings.openAppSettings(type: AppSettingsType.wifi);
                      },
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: const Text('WiFi Ayarlarına Git'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            theme.colorScheme.onSurface.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showConnectionRestoredDialog() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (_isDialogShowing) {
      Navigator.of(context, rootNavigator: true)
          .pop(); // Pencereyi programatik olarak kapat
      _isDialogShowing = false;
    }

    String message = 'Connection restored';
    try {
      final langVM = Provider.of<LanguageViewModel>(context, listen: false);
      final translated = langVM.translate('connection_restored');
      if (translated != 'connection_restored') {
        message = translated;
      }
    } catch (_) {}

    CustomSnackbars.showSuccess(context, message);
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
  bool _isBottomNavVisible = true;
  bool _isExtended = false;

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

    // Arka plandan (Background) bildirime tıklanarak açılış
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      String payload = message.data['type'] ?? '';
      if (payload == 'question_reply' && message.data['questionId'] != null) {
        payload += ':${message.data['questionId']}';
      } else if (payload == 'review_reply' &&
          message.data['reviewId'] != null) {
        payload += ':${message.data['reviewId']}';
      } else if (message.data['payload'] != null) {
        payload = message.data['payload'];
      }
      if (payload.isNotEmpty) {
        _handleNotificationNavigation(payload);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
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
    if (payload.startsWith('question_reply')) {
      String? questionId;
      if (payload.contains(':')) {
        questionId = payload.split(':')[1];
      }
      navigatorKey.currentState?.push(
        MaterialPageRoute(
            builder: (_) => MyQuestionsScreen(highlightQuestionId: questionId)),
      );
      return;
    }

    // 2. Değerlendirme Yanıtı Bildirimi
    if (payload.startsWith('review_reply')) {
      String? reviewId;
      if (payload.contains(':')) {
        reviewId = payload.split(':')[1];
      }
      navigatorKey.currentState?.push(
        MaterialPageRoute(
            builder: (_) => MyReviewsScreen(highlightReviewId: reviewId)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 800; // Web kontrolü

    Widget buildNavItem(
      int itemIndex,
      String label,
      Widget Function(Color) iconBuilder,
    ) {
      final isSelected = _index == itemIndex;
      final primaryColor = theme.colorScheme.primary;
      final color = isSelected ? primaryColor : Colors.grey.withOpacity(0.8);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_index != itemIndex) {
            setState(() {
              _index = itemIndex;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconBuilder(color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              ]),
        ),
      );
    }

    return Scaffold(
        extendBody: true,
        drawerScrimColor:
            Colors.black.withOpacity(0.6), // Arka plan karartma rengi
        onDrawerChanged: (isOpened) {
          setState(() {
            _isDrawerOpen = isOpened;
          });
        },
        drawer:
            isDesktop ? null : const SideMenuDrawer(), // Web'de drawer gizlenir
        body: NotificationListener<ScrollUpdateNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical) {
              final dy = notification.scrollDelta ?? 0;
              if (notification.metrics.pixels <=
                  notification.metrics.minScrollExtent) {
                if (!_isBottomNavVisible)
                  setState(() => _isBottomNavVisible = true);
              } else if (dy > 4 && _isBottomNavVisible) {
                setState(() => _isBottomNavVisible = false);
              } else if (dy < -4 && !_isBottomNavVisible) {
                setState(() => _isBottomNavVisible = true);
              }
            }
            return false;
          },
          child: Stack(
            children: [
              Row(
                children: [
                  if (isDesktop)
                    NavigationRail(
                      extended: _isExtended,
                      minExtendedWidth: 200,
                      leading: IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () =>
                            setState(() => _isExtended = !_isExtended),
                      ),
                      selectedIndex: _index,
                      onDestinationSelected: (i) => setState(() => _index = i),
                      labelType: _isExtended
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.storefront_outlined),
                          selectedIcon: const Icon(Icons.storefront),
                          label: Text(langVM.translate('home_title')),
                        ),
                        NavigationRailDestination(
                          icon: SvgIcon(
                              iconPath: AppIcons.search,
                              color: Colors.grey,
                              size: 24),
                          selectedIcon: SvgIcon(
                              iconPath: AppIcons.searchActive,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24),
                          label: Text(langVM.translate('search_tab')),
                        ),
                        NavigationRailDestination(
                          icon: SvgIcon(
                              iconPath: AppIcons.products,
                              color: Colors.grey,
                              size: 24),
                          selectedIcon: SvgIcon(
                              iconPath: AppIcons.productsActive,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24),
                          label: Text(langVM.translate('products_tab')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.report_outlined),
                          selectedIcon: const Icon(Icons.report),
                          label: Text(langVM.translate('report_tab')),
                        ),
                      ],
                    ),
                  if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: 1200), // İçerik çok uzamasın
                        child: IndexedStack(index: _index, children: _screens),
                      ),
                    ),
                  ),
                ],
              ),
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
        ),
        bottomNavigationBar: _isDrawerOpen || isDesktop
            ? null
            : AnimatedSlide(
                offset:
                    _isBottomNavVisible ? Offset.zero : const Offset(0, 1.5),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161616) : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: true,
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildNavItem(
                            0,
                            langVM.translate('home_title'),
                            (c) => Icon(
                              _index == 0
                                  ? Icons.storefront
                                  : Icons.storefront_outlined,
                              color: c,
                              size: 24,
                            ),
                          ),
                          buildNavItem(
                            1,
                            langVM.translate('search_tab'),
                            (c) => SvgIcon(
                              iconPath: _index == 1
                                  ? AppIcons.searchActive
                                  : AppIcons.search,
                              color: c,
                              size: 24,
                            ),
                          ),
                          buildNavItem(
                            2,
                            langVM.translate('products_tab'),
                            (c) => SvgIcon(
                              iconPath: _index == 2
                                  ? AppIcons.productsActive
                                  : AppIcons.products,
                              color: c,
                              size: 24,
                            ),
                          ),
                          buildNavItem(
                            3,
                            langVM.translate('report_tab'),
                            (c) => Icon(
                              _index == 3
                                  ? Icons.report
                                  : Icons.report_outlined,
                              color: c,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ));
  }
}
