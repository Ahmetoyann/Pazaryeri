import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../../data/models/market.dart';
import 'report_form_screen.dart';

class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});

  void _showMarketSelection(BuildContext context, {required bool isForSeller}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MarketSelectionScreen(isForSeller: isForSeller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: Text(langVM.translate('report_tab'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildOptionCard(
                  context,
                  title: langVM.translate('report_seller_option'),
                  icon: Icons.storefront,
                  color: Colors.orange,
                  onTap: () => _showMarketSelection(context, isForSeller: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOptionCard(
                  context,
                  title: langVM.translate('report_market_option'),
                  icon: Icons.location_city,
                  color: Colors.blue,
                  onTap: () =>
                      _showMarketSelection(context, isForSeller: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(12.0),
          child: Stack(
            children: [
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.arrow_outward,
                  color: Colors.white.withOpacity(0.5),
                  size: 24,
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 48, color: color),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketSelectionScreen extends StatefulWidget {
  final bool isForSeller;

  const _MarketSelectionScreen({required this.isForSeller});

  @override
  State<_MarketSelectionScreen> createState() => _MarketSelectionScreenState();
}

class _MarketSelectionScreenState extends State<_MarketSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final homeVM = context.watch<HomeViewModel>();

    final Set<Market> allMarkets = {};
    allMarkets.addAll(homeVM.nearbyMarkets);
    allMarkets.addAll(homeVM.provinceMarkets);

    final marketList = allMarkets.where((market) {
      final query = _searchQuery.toLowerCase();
      return market.name.toLowerCase().contains(query) ||
          market.address.district.toLowerCase().contains(query) ||
          market.address.city.toLowerCase().contains(query);
    }).toList();

    // Alfabetik sırala
    marketList.sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: Text(langVM.translate('select_market_to_report')),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 110),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: langVM.translate('search_placeholder'),
                  hintStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Expanded(
              child: marketList.isEmpty
                  ? Center(child: Text(langVM.translate('no_results')))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: marketList.length,
                      itemBuilder: (context, index) {
                        final market = marketList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(market.name),
                            subtitle: Text(
                                '${market.address.district}, ${market.address.city}'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              if (widget.isForSeller) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        _SellerSelectionScreen(market: market),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportFormScreen(
                                      marketId: market.id,
                                      marketName: market.name,
                                    ),
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
        ),
      ),
    );
  }
}

class _SellerSelectionScreen extends StatelessWidget {
  final Market market;

  const _SellerSelectionScreen({required this.market});

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(langVM.translate('select_seller_to_report')),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: AuthService.instance.getMarketSellers(market.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text(
                    '${langVM.translate('error_prefix')}: ${snapshot.error}'));
          }

          final sellers = snapshot.data ?? [];

          if (sellers.isEmpty) {
            return Center(
              child: Text(langVM.translate('no_sellers_found')),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
            itemCount: sellers.length,
            itemBuilder: (context, index) {
              final seller = sellers[index];
              String displayName = seller['stallName'] ?? '';
              if (displayName.isEmpty) {
                displayName =
                    '${seller['firstName'] ?? ''} ${seller['lastName'] ?? ''}'
                        .trim();
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(24),
                  leading: const Icon(Icons.store, size: 40),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    seller['stallDescription'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportFormScreen(
                          marketId: market.id,
                          marketName: market.name,
                          sellerId: seller['id'],
                          sellerName: displayName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
