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
import '../Customer/notifications_screen.dart';
import 'seller_questions_screen.dart';

class SellerMainScreen extends StatefulWidget {
  final int initialIndex;
  // Varsayılan değer 0 (Ürün Ekle) olarak ayarlandı
  const SellerMainScreen({super.key, this.initialIndex = 0});

  @override
  State<SellerMainScreen> createState() => _SellerMainScreenState();
}

class _SellerMainScreenState extends State<SellerMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // Başlangıç sekmesini parametreden al
    _currentIndex = widget.initialIndex;
    // Ekran açıldığında ürünleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
      final authVM = Provider.of<AuthViewModel>(context, listen: false);

      // Eğer pazar seçili değilse ama ID varsa (Otomatik giriş)
      if (sellerVM.selectedMarket == null &&
          authVM.sellerMarketId != null &&
          authVM.sellerMarketId!.isNotEmpty) {
        await sellerVM.loadMarketById(authVM.sellerMarketId!);
      }
      sellerVM.loadProducts();
    });
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

  Widget _buildBottomNavIcon(BuildContext context, IconData icon,
      AuthViewModel authVM, String? notificationType,
      {bool isActive = false}) {
    if (authVM.currentUser == null || notificationType == null) {
      return isActive ? _buildActiveIcon(context, icon) : Icon(icon, size: 30);
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

        final mainIcon =
            isActive ? _buildActiveIcon(context, icon) : Icon(icon, size: 30);

        if (unreadCount == 0) return mainIcon;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            mainIcon,
            Positioned(
              right: isActive ? 0 : -2,
              top: isActive ? 0 : -2,
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
      BuildContext context, IconData icon, AuthViewModel authVM,
      {bool isActive = false}) {
    if (authVM.currentUser == null) {
      return isActive ? _buildActiveIcon(context, icon) : Icon(icon, size: 30);
    }

    return StreamBuilder<int>(
      stream: AuthService.instance
          .getUnansweredQuestionsCount(authVM.currentUser!.id),
      builder: (context, snapshot) {
        int count = snapshot.data ?? 0;

        final mainIcon =
            isActive ? _buildActiveIcon(context, icon) : Icon(icon, size: 30);

        if (count == 0) return mainIcon;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            mainIcon,
            Positioned(
              right: isActive ? 0 : -2,
              top: isActive ? 0 : -2,
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

    final List<Widget> pages = [
      const SellerProductsScreen(),
      const SellerStatsScreen(),
      const SellerAddProductScreen(),
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
                    const Icon(Icons.notifications),
                    if (unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
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
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
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
        padding: const EdgeInsets.only(top: 110),
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                showSelectedLabels: false,
                showUnselectedLabels: false,
                selectedFontSize: 3,
                unselectedFontSize: 0,
                iconSize: 30,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.list_alt),
                    activeIcon: _buildActiveIcon(context, Icons.list_alt),
                    label: langVM.translate('my_products_tab'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.bar_chart),
                    activeIcon: _buildActiveIcon(context, Icons.bar_chart),
                    label: langVM.translate('statistics_tab'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.add_circle_outline),
                    activeIcon: _buildActiveIcon(context, Icons.add_circle),
                    label: langVM.translate('add_product_tab'),
                  ),
                  BottomNavigationBarItem(
                    icon: _buildQuestionTabIcon(
                        context, Icons.help_outline, authVM,
                        isActive: false),
                    activeIcon: _buildQuestionTabIcon(
                        context, Icons.help, authVM,
                        isActive: true),
                    label: 'Sorular',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildBottomNavIcon(
                        context, Icons.star_outline, authVM, 'new_review',
                        isActive: false),
                    activeIcon: _buildBottomNavIcon(
                        context, Icons.star, authVM, 'new_review',
                        isActive: true),
                    label: langVM.translate('reviews_tab'),
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
