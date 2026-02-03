import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../Customer/customer_seller_detail_screen.dart';
import '../../widgets/custom_app_bar.dart';

class MarketSellersScreen extends StatefulWidget {
  final String marketId;
  final String marketName;

  const MarketSellersScreen({
    super.key,
    required this.marketId,
    required this.marketName,
  });

  @override
  State<MarketSellersScreen> createState() => _MarketSellersScreenState();
}

class _MarketSellersScreenState extends State<MarketSellersScreen> {
  List<Map<String, dynamic>> _sellers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  Future<void> _loadSellers() async {
    final sellers =
        await AuthService.instance.fetchSellersForMarket(widget.marketId);
    if (mounted) {
      setState(() {
        _sellers = sellers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title:
            Text('${widget.marketName} - ${langVM.translate('sellers_title')}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sellers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store_mall_directory_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        langVM.translate('no_sellers_found'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
                  itemCount: _sellers.length,
                  itemBuilder: (context, index) {
                    final seller = _sellers[index];
                    // İsim oluşturma (Ad Soyad veya Tezgah Adı)
                    String displayName = seller['stallName'] ?? '';
                    if (displayName.isEmpty) {
                      displayName =
                          '${seller['firstName'] ?? ''} ${seller['lastName'] ?? ''}'
                              .trim();
                    }
                    if (displayName.isEmpty) displayName = 'Satıcı';

                    final description =
                        seller['stallDescription'] ?? 'Açıklama yok';
                    final stallLocation = seller['stallLocation'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          backgroundImage: (seller['profilePicture'] != null &&
                                  seller['profilePicture'].isNotEmpty)
                              ? NetworkImage(seller['profilePicture'])
                              : null,
                          child: (seller['profilePicture'] == null ||
                                  seller['profilePicture'].isEmpty)
                              ? Text(
                                  displayName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                )
                              : null,
                        ),
                        title: Text(displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerSellerDetailScreen(
                                sellerId: seller['id'],
                                sellerName: displayName,
                                sellerDescription: description,
                                stallLocation: stallLocation,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
