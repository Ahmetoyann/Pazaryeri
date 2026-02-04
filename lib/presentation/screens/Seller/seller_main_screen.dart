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

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);

    final List<Widget> pages = [
      SellerAddProductScreen(onProductAdded: () {
        setState(() => _currentIndex = 1);
      }),
      const SellerProductsScreen(),
      const SellerStatsScreen(),
      const SellerReviewsScreen(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: Text(sellerVM.selectedMarket?.name ??
            langVM.translate('seller_panel_title')),
        actions: [
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
        padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
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
                    icon: const Icon(Icons.add_circle_outline),
                    activeIcon: _buildActiveIcon(context, Icons.add_circle),
                    label: langVM.translate('add_product_tab'),
                  ),
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
                    icon: const Icon(Icons.star_outline),
                    activeIcon: _buildActiveIcon(context, Icons.star),
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
