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

  final List<Widget> _pages = const [
    SellerAddProductScreen(),
    SellerProductsScreen(),
    SellerStatsScreen(),
    SellerReviewsScreen(),
  ];

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

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: Text(sellerVM.selectedMarket?.name ??
            langVM.translate('seller_panel_title')),
        actions: [
          Tooltip(
            message: sellerVM.isStallOpen
                ? langVM.translate('stall_open')
                : langVM.translate('stall_closed'),
            child: Switch(
              value: sellerVM.isStallOpen,
              onChanged: (val) => sellerVM.toggleStallStatus(val),
              activeColor: Colors.green,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: langVM.translate('change_market'),
            onPressed: () async {
              final authVM = Provider.of<AuthViewModel>(context, listen: false);
              // Mevcut pazar seçimini yerel hafızadan temizle
              await AuthService.instance.updateSellerMarketId('');
              authVM.setSellerMarketId('');

              // AuthWrapper durumu dinlediği için otomatik yönlendirme yapacaktır.
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
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: langVM.translate('exit_seller_panel'),
            onPressed: () {
              Provider.of<AuthViewModel>(context, listen: false).logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      extendBody: true,
      body: Padding(
        padding: const EdgeInsets.only(top: 110),
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
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
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.add_circle_outline),
                    label: langVM.translate('add_product_tab'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.list_alt),
                    label: langVM.translate('my_products_tab'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.bar_chart),
                    label: langVM.translate('statistics_tab'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.star_outline),
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
