import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';
import '../../widgets/custom_button.dart';

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
  bool _isVerificationDismissed = false;
  bool _isBottomNavVisible = true;

  @override
  void initState() {
    super.initState();
    // Başlangıç sekmesini parametreden al
    _currentIndex = widget.initialIndex;

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
    super.dispose();
  }

  void _showEmailVerificationSheet(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    CustomBottomSheets.showContent(
      context: context,
      title: 'E-postanızı Doğrulayın',
      icon: Icons.mark_email_unread_outlined,
      child: Column(
        children: [
          Text(
            langVM.translate('email_not_verified_message'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Doğrula',
            onPressed: () async {
              try {
                await firebase_auth.FirebaseAuth.instance.currentUser
                    ?.sendEmailVerification();
                if (context.mounted) {
                  Navigator.pop(context);
                  CustomSnackbars.showSuccess(
                    context,
                    'Doğrulama epostası gönderildi',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  CustomSnackbars.showError(
                    context,
                    '${langVM.translate('error_prefix')}: $e',
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavIcon(BuildContext context, String iconPath,
      AuthViewModel authVM, String? notificationType, Color color) {
    if (authVM.currentUser == null || notificationType == null) {
      return SvgIcon(iconPath: iconPath, size: 24, color: color);
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

        final mainIcon = SvgIcon(iconPath: iconPath, size: 24, color: color);

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

  Widget _buildQuestionTabIcon(BuildContext context, String iconPath,
      AuthViewModel authVM, Color color) {
    if (authVM.currentUser == null) {
      return SvgIcon(iconPath: iconPath, size: 24, color: color);
    }

    return StreamBuilder<int>(
      stream: AuthService.instance
          .getUnansweredQuestionsCount(authVM.currentUser!.id),
      builder: (context, snapshot) {
        int count = snapshot.data ?? 0;

        final mainIcon = SvgIcon(iconPath: iconPath, size: 24, color: color);

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
    final unselectedIconColor =
        isDark ? Colors.white60 : Colors.grey.withOpacity(0.8);

    Widget buildNavItem(
      int itemIndex,
      String label,
      Widget Function(Color) iconBuilder,
    ) {
      final isSelected = _currentIndex == itemIndex;
      final primaryColor = theme.colorScheme.primary;
      final color = isSelected ? primaryColor : unselectedIconColor;

      return GestureDetector(
        onTap: () {
          if (_currentIndex != itemIndex) {
            setState(() {
              _currentIndex = itemIndex;
            });
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              padding: EdgeInsets.symmetric(
                horizontal:
                    isSelected ? 12 : 10, // 5 eleman için padding daraltıldı
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.2)
                    : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? primaryColor.withOpacity(0.5)
                      : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconBuilder(color),
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize:
                            10, // 5 eleman sığması için font biraz daraltıldı
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final List<Widget> pages = [
      SellerProductsScreen(
        onSwitchToAddProductTab: () {
          setState(() {
            _currentIndex = 2; // Ürün Ekle sekmesinin indeksi
          });
        },
      ),
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
          child: Column(
            children: [
              StreamBuilder<firebase_auth.User?>(
                stream: firebase_auth.FirebaseAuth.instance.userChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user != null &&
                      !user.emailVerified &&
                      !_isVerificationDismissed) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF5350), Color(0xFFFF7043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF5350).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    _showEmailVerificationSheet(context),
                                borderRadius: BorderRadius.circular(16),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.mark_email_unread,
                                          color: Colors.white),
                                      SizedBox(width: 12),
                                      Text(
                                        'E-postanızı Doğrulayın',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _isVerificationDismissed = true),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(Icons.close,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AnimatedSlide(
          offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1.5),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  theme.scaffoldBackgroundColor,
                  theme.scaffoldBackgroundColor.withOpacity(isDark ? 0.9 : 0.7),
                  theme.scaffoldBackgroundColor.withOpacity(isDark ? 0.4 : 0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 0.9, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: true,
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildNavItem(
                      0,
                      langVM.translate('my_products_tab'),
                      (c) => SvgIcon(
                        iconPath: _currentIndex == 0
                            ? AppIcons.inventoryActive
                            : AppIcons.inventory,
                        color: c,
                        size: 24,
                      ),
                    ),
                    buildNavItem(
                      1,
                      langVM.translate('statistics_tab'),
                      (c) => Icon(
                        _currentIndex == 1
                            ? Icons.bar_chart_rounded
                            : Icons.bar_chart_outlined,
                        color: c,
                        size: 24,
                      ),
                    ),
                    buildNavItem(
                      2,
                      langVM.translate('add_product_tab'),
                      (c) => SvgIcon(
                        iconPath: _currentIndex == 2
                            ? AppIcons.addActive
                            : AppIcons.add,
                        color: c,
                        size: 24,
                      ),
                    ),
                    buildNavItem(
                      3,
                      langVM.translate('questions_tab'),
                      (c) => _buildQuestionTabIcon(
                        context,
                        _currentIndex == 3
                            ? AppIcons.questionActive
                            : AppIcons.question,
                        authVM,
                        c,
                      ),
                    ),
                    buildNavItem(
                      4,
                      langVM.translate('reviews_tab_short'),
                      (c) => _buildBottomNavIcon(
                        context,
                        _currentIndex == 4
                            ? AppIcons.star
                            : AppIcons.starBorder,
                        authVM,
                        'new_review',
                        c,
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
