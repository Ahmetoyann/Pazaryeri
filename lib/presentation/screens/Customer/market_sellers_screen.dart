import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
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
      appBar: AppBar(
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
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          final sellers = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sellers.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (context, index) {
              final seller = sellers[index];
              final stallName = seller['stallName'] ??
                  seller['name'] ??
                  '${seller['firstName'] ?? ''} ${seller['lastName'] ?? ''}'
                      .trim();
              final stallDesc = seller['stallDescription'] ?? '';
              final profilePic = seller['profilePicture'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                      ? NetworkImage(profilePic)
                      : null,
                  child: (profilePic == null || profilePic.isEmpty)
                      ? const Icon(Icons.person)
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
              );
            },
          );
        },
      ),
    );
  }
}
