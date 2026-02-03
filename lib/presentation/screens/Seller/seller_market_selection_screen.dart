import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../../data/models/market.dart';
import '../../widgets/custom_app_bar.dart';

class SellerMarketSelectionScreen extends StatefulWidget {
  const SellerMarketSelectionScreen({super.key});

  @override
  State<SellerMarketSelectionScreen> createState() =>
      _SellerMarketSelectionScreenState();
}

class _SellerMarketSelectionScreenState
    extends State<SellerMarketSelectionScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında kayıtlı seçim var mı kontrol et
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkExistingSelection());
  }

  Future<void> _checkExistingSelection() async {
    final userData = await AuthService.instance.getUserData();
    // Eğer kullanıcı daha önce bir pazar seçmişse (sellerMarketId doluysa)
    if (userData != null &&
        userData['sellerMarketId'] != null &&
        userData['sellerMarketId']!.isNotEmpty) {
      if (mounted) {
        final authVM = Provider.of<AuthViewModel>(context, listen: false);
        authVM.setSellerMarketId(userData['sellerMarketId']!);
        return;
      }
    }
    // Seçim yoksa listeyi göster
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
    final langVM = Provider.of<LanguageViewModel>(context);

    // Kontrol sürerken yükleniyor göster
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: Text(langVM.translate('select_market_title')),
      ),
      body: FutureBuilder<List<Market>>(
        future: sellerVM.getMarkets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(langVM.translate('no_results')));
          }

          final markets = snapshot.data!;

          return Column(
            children: [
              const SizedBox(height: 110), // AppBar için boşluk
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  langVM.translate('select_market_instruction'),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: markets.length,
                  itemBuilder: (context, index) {
                    final market = markets[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.storefront),
                        title: Text(market.name),
                        subtitle: Text(market.address.district),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          // İşlem başladığında yükleniyor dialogunu göster
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            useRootNavigator: false,
                            builder: (ctx) => const Center(
                                child: CircularProgressIndicator()),
                          );

                          // 1. Seçimi ViewModel'e bildir
                          sellerVM.selectMarket(market);
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);
                          final authVM = Provider.of<AuthViewModel>(context,
                              listen: false);

                          try {
                            // 2. Seçimi Kalıcı Olarak Kaydet (DB ve Yerel)
                            if (authVM.currentUser != null) {
                              // Firestore'a kaydet ki diğer kullanıcılar görebilsin
                              await AuthService.instance.updateUserInDb({
                                'sellerMarketId': market.id,
                                'isSeller': true, // Satıcı olarak işaretle
                              }, authVM.currentUser!.email).timeout(
                                const Duration(seconds: 5),
                                onTimeout: () {
                                  // Bağlantı yavaşsa bekleme, yerel olarak devam et
                                  debugPrint(
                                      'Bulut güncellemesi zaman aşımı, yerel devam ediliyor.');
                                },
                              );

                              await AuthService.instance
                                  .updateSellerMarketId(market.id);
                            }

                            // İşlem başarılı, yükleniyor dialogunu kapat
                            navigator.pop();

                            // Dialog kapandıktan sonra ekran geçişini tetikle
                            if (authVM.currentUser != null) {
                              authVM.setSellerMarketId(market.id);
                            }
                          } catch (e) {
                            // Hata oluştu, yükleniyor dialogunu kapat
                            navigator.pop();

                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${langVM.translate('error_prefix')}: $e'),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
