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
  late AnimationController _pulseController;
  bool _isVerificationDismissed = false;
  Timer? _indicatorTimer;
  bool _isMoving = false;

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
    _indicatorTimer?.cancel();
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
      AuthViewModel authVM, String? notificationType,
      {bool isActive = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isActive
        ? theme.colorScheme.primary
        : (isDark ? Colors.white60 : Colors.black54);

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
    final isDark = theme.brightness == Brightness.dark;
    final color = isActive
        ? theme.colorScheme.primary
        : (isDark ? Colors.white60 : Colors.black54);

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
    final unselectedIconColor = isDark ? Colors.white60 : Colors.black54;
    const darkNavBackground = Color(0xFF1A1A1A);
    Widget navBox({
      required Widget icon,
      required String label,
      required bool selected,
    }) {
      final base = theme.colorScheme.primary;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuint,
        height: 48,
        constraints: BoxConstraints(
          minWidth: selected ? 82 : 60,
          maxWidth:
              selected ? 88 : 68, // Hem taşmayı önler hem hapları genişletir
        ),
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 10 : 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: selected ? base : null,
          gradient: selected
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark ? Colors.white : Colors.black)
                        .withOpacity(isDark ? 0.18 : 0.12),
                    (isDark ? Colors.white : Colors.black)
                        .withOpacity(isDark ? 0.08 : 0.04),
                  ],
                ),
          border: Border.all(
            color: selected
                ? base
                : (isDark ? Colors.white : Colors.black).withOpacity(0.20),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!selected) icon, // Seçili değilse ikonu göster
            if (selected) // Seçiliyse sadece metni göster
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown, // Metni kesmek yerine alana sığdır
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

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
        body: Column(
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
                              onTap: () => _showEmailVerificationSheet(context),
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: null,
            boxShadow: const [],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: SizedBox(
                height: 75 + MediaQuery.of(context).padding.bottom,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.white)
                                .withOpacity(isDark ? 0.4 : 0.5),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 0,
                        right:
                            0, // Hapların tam yayılması ve yakınlaşması için yan boşlukları sıfırladık
                        bottom: MediaQuery.of(context).padding.bottom,
                      ),
                      child: MediaQuery.removePadding(
                        context: context,
                        removeBottom: true,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                          ),
                          child: BottomNavigationBar(
                            currentIndex: _currentIndex,
                            onTap: (index) {
                              if (_currentIndex == index) return;
                              setState(() {
                                _currentIndex = index;
                                _isMoving = true;
                              });
                              _indicatorTimer?.cancel();
                              _indicatorTimer =
                                  Timer(const Duration(milliseconds: 300), () {
                                if (mounted) setState(() => _isMoving = false);
                              });
                            },
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            type: BottomNavigationBarType.fixed,
                            showSelectedLabels: false,
                            showUnselectedLabels: false,
                            selectedItemColor: theme.colorScheme.primary,
                            unselectedItemColor: Colors.grey,
                            unselectedFontSize: 8,
                            selectedFontSize: 10,
                            iconSize: 28,
                            items: [
                              BottomNavigationBarItem(
                                icon: AnimatedScale(
                                  scale: _isMoving ? 0.8 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: AnimatedOpacity(
                                    opacity: _isMoving ? 0.5 : 1.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: navBox(
                                      label:
                                          langVM.translate('my_products_tab'),
                                      selected: false,
                                      icon: SvgIcon(
                                          iconPath: AppIcons.inventory,
                                          size: 24,
                                          color: unselectedIconColor),
                                    ),
                                  ),
                                ),
                                activeIcon: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutBack,
                                  tween: Tween(begin: 0.5, end: 1.0),
                                  builder: (context, value, child) =>
                                      Transform.scale(
                                    scale: value,
                                    child: child,
                                  ),
                                  child: navBox(
                                    label: langVM.translate('my_products_tab'),
                                    selected: true,
                                    icon: SvgIcon(
                                        iconPath: AppIcons.inventoryActive,
                                        size: 24,
                                        color: theme.colorScheme.primary),
                                  ),
                                ),
                                label: '',
                              ),
                              BottomNavigationBarItem(
                                icon: AnimatedScale(
                                  scale: _isMoving ? 0.8 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: AnimatedOpacity(
                                    opacity: _isMoving ? 0.5 : 1.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: navBox(
                                      label: langVM.translate('statistics_tab'),
                                      selected: false,
                                      icon: SvgIcon(
                                          iconPath: AppIcons.chart,
                                          size: 24,
                                          color: unselectedIconColor),
                                    ),
                                  ),
                                ),
                                activeIcon: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutBack,
                                  tween: Tween(begin: 0.5, end: 1.0),
                                  builder: (context, value, child) =>
                                      Transform.scale(
                                    scale: value,
                                    child: child,
                                  ),
                                  child: navBox(
                                    label: langVM.translate('statistics_tab'),
                                    selected: true,
                                    icon: Icon(Icons.bar_chart_rounded,
                                        size: 24,
                                        color: theme.colorScheme.primary),
                                  ),
                                ),
                                label: '',
                              ),
                              BottomNavigationBarItem(
                                icon: ScaleTransition(
                                  scale: Tween<double>(begin: 1.0, end: 1.1)
                                      .animate(
                                    CurvedAnimation(
                                      parent: _pulseController,
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                  child: Transform.translate(
                                    offset: const Offset(0, 0),
                                    child: navBox(
                                      label:
                                          langVM.translate('add_product_tab'),
                                      selected: false,
                                      icon: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? darkNavBackground
                                                : Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Center(
                                          child: SvgIcon(
                                              iconPath: AppIcons.add,
                                              size: 20,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                activeIcon: ScaleTransition(
                                  scale: Tween<double>(begin: 1.0, end: 1.1)
                                      .animate(
                                    CurvedAnimation(
                                      parent: _pulseController,
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                  child: Transform.translate(
                                    offset: const Offset(0, 0),
                                    child: navBox(
                                      label:
                                          langVM.translate('add_product_tab'),
                                      selected: true,
                                      icon: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? darkNavBackground
                                                : Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: SvgIcon(
                                              iconPath: AppIcons.addActive,
                                              size: 20,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                label: '',
                              ),
                              BottomNavigationBarItem(
                                icon: AnimatedScale(
                                  scale: _isMoving ? 0.8 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: AnimatedOpacity(
                                    opacity: _isMoving ? 0.5 : 1.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: navBox(
                                      label: langVM.translate('questions_tab'),
                                      selected: false,
                                      icon: _buildQuestionTabIcon(
                                          context, AppIcons.question, authVM,
                                          isActive: false),
                                    ),
                                  ),
                                ),
                                activeIcon: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutBack,
                                  tween: Tween(begin: 0.5, end: 1.0),
                                  builder: (context, value, child) =>
                                      Transform.scale(
                                    scale: value,
                                    child: child,
                                  ),
                                  child: navBox(
                                    label: langVM.translate('questions_tab'),
                                    selected: true,
                                    icon: _buildQuestionTabIcon(context,
                                        AppIcons.questionActive, authVM,
                                        isActive: true),
                                  ),
                                ),
                                label: '',
                              ),
                              BottomNavigationBarItem(
                                icon: AnimatedScale(
                                  scale: _isMoving ? 0.8 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: AnimatedOpacity(
                                    opacity: _isMoving ? 0.5 : 1.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: navBox(
                                      label:
                                          langVM.translate('reviews_tab_short'),
                                      selected: false,
                                      icon: _buildBottomNavIcon(
                                          context,
                                          AppIcons.starBorder,
                                          authVM,
                                          'new_review',
                                          isActive: false),
                                    ),
                                  ),
                                ),
                                activeIcon: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutBack,
                                  tween: Tween(begin: 0.5, end: 1.0),
                                  builder: (context, value, child) =>
                                      Transform.scale(
                                    scale: value,
                                    child: child,
                                  ),
                                  child: navBox(
                                    label:
                                        langVM.translate('reviews_tab_short'),
                                    selected: true,
                                    icon: _buildBottomNavIcon(context,
                                        AppIcons.star, authVM, 'new_review',
                                        isActive: true),
                                  ),
                                ),
                                label: '',
                              ),
                            ],
                          ),
                        ),
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
