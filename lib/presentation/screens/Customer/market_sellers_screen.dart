import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'seller_products_view_screen.dart';

class MarketSellersScreen extends StatelessWidget {
  final String marketId;
  final String marketName;

  const MarketSellersScreen({
    super.key,
    required this.marketId,
    required this.marketName,
  });

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: Text(langVM.translate('sellers_title')),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: AuthService.instance.fetchSellersForMarket(marketId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                langVM.translate('no_sellers_found'),
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6)),
              ),
            );
          }

          final sellers = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
            itemCount: sellers.length,
            itemBuilder: (context, index) {
              final seller = sellers[index];
              final stallName = seller['stallName'] ??
                  seller['name'] ??
                  '${seller['firstName'] ?? ''} ${seller['lastName'] ?? ''}'
                      .trim();
              final stallDesc = seller['stallDescription'] ?? '';
              final profilePic = seller['profilePicture'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    backgroundImage:
                        (profilePic != null && profilePic.isNotEmpty)
                            ? NetworkImage(profilePic)
                            : null,
                    child: (profilePic == null || profilePic.isEmpty)
                        ? Icon(Icons.person,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  title: Text(
                    stallName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: stallDesc.isNotEmpty
                      ? Text(stallDesc,
                          maxLines: 2, overflow: TextOverflow.ellipsis)
                      : null,
                  isThreeLine: stallDesc.isNotEmpty,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SellerProductsViewScreen(seller: seller),
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
