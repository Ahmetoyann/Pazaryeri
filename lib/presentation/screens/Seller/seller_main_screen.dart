import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import 'seller_add_product_screen.dart';
import 'seller_reviews_screen.dart';
import 'seller_products_screen.dart';
import 'seller_settings_screen.dart';
import 'seller_stats_screen.dart';
import '../../widgets/custom_app_bar.dart';
import 'seller_notifications_screen.dart';
import 'seller_questions_screen.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';

class SellerMainScreen extends StatefulWidget {
  final int initialIndex;
  // Varsayılan değer 0 (Ürün Ekle) olarak ayarlandı
  const SellerMainScreen({super.key, this.initialIndex = 0});

  @override
  State<SellerMainScreen> createState() => _SellerMainScreenState();
}

class _SellerMainScreenState extends State<SellerMainScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Başlangıç sekmesini parametreden al
    _currentIndex = widget.initialIndex;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Ekran açıldığında ürünleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
      final authVM = Provider.of<AuthViewModel>(context, listen: false);

      try {
        // Eğer pazar seçili değilse ama ID varsa (Otomatik giriş)
        if (sellerVM.selectedMarket == null &&
            authVM.sellerMarketId != null &&
            authVM.sellerMarketId!.isNotEmpty) {
          await sellerVM.loadMarketById(authVM.sellerMarketId!);
        }
        await sellerVM.loadProducts();
      } catch (e, stackTrace) {
        debugPrint('Error initializing SellerMainScreen: $e\n$stackTrace');
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildBottomNavIcon(BuildContext context, String iconPath,
      AuthViewModel authVM, String? notificationType,
      {bool isActive = false}) {
    final theme = Theme.of(context);
    final color = isActive ? theme.colorScheme.primary : Colors.grey;

    if (authVM.currentUser == null || notificationType == null) {
      return SvgIcon(iconPath: iconPath, size: 28, color: color);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AuthService.instance.getUserNotifications(authVM.currentUser!.id),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          // Sadece ilgili tipteki okunmamış bildirimleri say
          unreadCount = snapshot.data!.where((n) {
            final isUnread = n['read'] == false;
            final type = n['metadata']?['type'];
            return isUnread && type == notificationType;
          }).length;
        }

        final mainIcon = SvgIcon(iconPath: iconPath, size: 28, color: color);

        if (unreadCount == 0) return mainIcon;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            mainIcon,
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionTabIcon(
      BuildContext context, String iconPath, AuthViewModel authVM,
      {bool isActive = false}) {
    final theme = Theme.of(context);
    final color = isActive ? theme.colorScheme.primary : Colors.grey;

    if (authVM.currentUser == null) {
      return SvgIcon(iconPath: iconPath, size: 28, color: color);
    }

    return StreamBuilder<int>(
      stream: AuthService.instance
          .getUnansweredQuestionsCount(authVM.currentUser!.id),
      builder: (context, snapshot) {
        int count = snapshot.data ?? 0;

        final mainIcon = SvgIcon(iconPath: iconPath, size: 28, color: color);

        if (count == 0) return mainIcon;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            mainIcon,
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      const SellerProductsScreen(),
      const SellerStatsScreen(),
      SellerAddProductScreen(
        onProductAdded: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      const SellerQuestionsScreen(),
      const SellerReviewsScreen(),
    ];

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          title: Text(sellerVM.selectedMarket?.name ??
              langVM.translate('seller_panel_title')),
          actions: [
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: authVM.currentUser != null
                  ? AuthService.instance
                      .getUserNotifications(authVM.currentUser!.id)
                  : null,
              builder: (context, snapshot) {
                int unreadCount = 0;
                if (snapshot.hasData) {
                  unreadCount =
                      snapshot.data!.where((n) => n['read'] == false).length;
                }
                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SvgIcon(iconPath: AppIcons.notification, size: 28),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SellerNotificationsScreen()),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: SvgIcon(iconPath: AppIcons.settings, size: 28),
              tooltip: langVM.translate('seller_settings_title'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerSettingsScreen()),
              ),
            ),
          ],
        ),
        extendBody: true,
        body: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
        ),
        bottomNavigationBar: Container(
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
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedItemColor: theme.colorScheme.primary,
                  unselectedItemColor: Colors.grey,
                  unselectedFontSize: 8,
                  selectedFontSize: 10,
                  iconSize: 28,
                  items: [
                    BottomNavigationBarItem(
                      icon: SvgIcon(
                          iconPath: AppIcons.inventory,
                          size: 28,
                          color: Colors.grey),
                      activeIcon: SvgIcon(
                          iconPath: AppIcons.inventoryActive,
                          size: 28,
                          color: theme.colorScheme.primary),
                      label: langVM.translate('my_products_tab'),
                    ),
                    BottomNavigationBarItem(
                      icon: SvgIcon(
                          iconPath: AppIcons.chart,
                          size: 28,
                          color: Colors.grey),
                      activeIcon: Icon(Icons.bar_chart_rounded,
                          size: 28, color: theme.colorScheme.primary),
                      label: langVM.translate('statistics_tab'),
                    ),
                    BottomNavigationBarItem(
                      icon: ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Transform.translate(
                          offset: const Offset(0, 0),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.black : Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: SvgIcon(
                                  iconPath: AppIcons.add,
                                  size: 32,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      activeIcon: ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Transform.translate(
                          offset: const Offset(0, 0),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.black : Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.6),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: SvgIcon(
                                  iconPath: AppIcons.addActive,
                                  size: 32,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      label: langVM.translate('add_product_tab'),
                    ),
                    BottomNavigationBarItem(
                      icon: _buildQuestionTabIcon(
                          context, AppIcons.question, authVM,
                          isActive: false),
                      activeIcon: _buildQuestionTabIcon(
                          context, AppIcons.questionActive, authVM,
                          isActive: true),
                      label: langVM.translate('questions_tab'),
                    ),
                    BottomNavigationBarItem(
                      icon: _buildBottomNavIcon(
                          context, AppIcons.starBorder, authVM, 'new_review',
                          isActive: false),
                      activeIcon: _buildBottomNavIcon(
                          context, AppIcons.star, authVM, 'new_review',
                          isActive: true),
                      label: langVM.translate('reviews_tab_short'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
