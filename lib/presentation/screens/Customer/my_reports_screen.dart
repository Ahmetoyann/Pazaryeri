import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../../data/models/market.dart';
import 'customer_seller_detail_screen.dart';
import 'market_detail_screen.dart';
import '../../widgets/loading_overlay.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final langVM = context.watch<LanguageViewModel>();
    final userId = authVM.currentUser?.id;

    return Scaffold(
      appBar: CustomAppBar(title: Text(langVM.translate('report_history'))),
      body: userId == null
          ? const Center(child: CustomLoadingIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('reporterId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CustomLoadingIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs.toList() ?? [];

                // İndeks hatasını önlemek için sıralamayı burada (istemci tarafında) yapıyoruz
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final tA = aData['timestamp'] as Timestamp?;
                  final tB = bData['timestamp'] as Timestamp?;
                  if (tA == null) return 1;
                  if (tB == null) return -1;
                  return tB.compareTo(tA); // Yeniden eskiye
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 80, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          langVM.translate('no_reports_yet'),
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final report = docs[index].data() as Map<String, dynamic>;
                    final date = report['timestamp'] != null
                        ? (report['timestamp'] as Timestamp).toDate()
                        : DateTime.now();
                    final formattedDate =
                        DateFormat('dd MMM yyyy HH:mm').format(date);

                    String statusKey =
                        'report_status_${report['status'] ?? 'pending'}';
                    String statusText = langVM.translate(statusKey);

                    Color statusColor = Colors.orange;
                    if (report['status'] == 'resolved') {
                      statusColor = Colors.green;
                    } else if (report['status'] == 'reviewed') {
                      statusColor = Colors.blue;
                    }

                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color:
                            isDark ? Theme.of(context).cardColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            if (report['type'] == 'seller' &&
                                report['reportedId'] != null) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                    child: CustomLoadingIndicator()),
                              );

                              try {
                                final sellerData = await AuthService.instance
                                    .refreshUserData(report['reportedId']);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  if (sellerData != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CustomerSellerDetailScreen(
                                          sellerId: sellerData['id']!,
                                          sellerName: sellerData['stallName']
                                                      ?.isNotEmpty ==
                                                  true
                                              ? sellerData['stallName']!
                                              : '${sellerData['firstName']} ${sellerData['lastName']}',
                                          sellerDescription:
                                              sellerData['stallDescription'] ??
                                                  '',
                                          stallLocation: '',
                                          stallHours:
                                              sellerData['stallHours'] ?? '',
                                          instagramLink:
                                              sellerData['instagramLink'],
                                          facebookLink:
                                              sellerData['facebookLink'],
                                          profilePicture:
                                              sellerData['profilePicture'],
                                          marketName: '',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) Navigator.pop(context);
                              }
                            } else if (report['type'] == 'market' &&
                                report['reportedId'] != null) {
                              final homeVM = Provider.of<HomeViewModel>(context,
                                  listen: false);
                              Market? market;
                              try {
                                market = homeVM.nearbyMarkets.firstWhere(
                                    (m) => m.id == report['reportedId']);
                              } catch (_) {
                                try {
                                  market = homeVM.provinceMarkets.firstWhere(
                                      (m) => m.id == report['reportedId']);
                                } catch (_) {}
                              }

                              if (market != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MarketDetailScreen(market: market!),
                                  ),
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (report['type'] == 'seller'
                                                ? Colors.blue
                                                : Colors.orange)
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        report['type'] == 'seller'
                                            ? Icons.people
                                            : Icons.storefront,
                                        color: report['type'] == 'seller'
                                            ? Colors.blue
                                            : Colors.orange,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${report['reportedName']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color:
                                                statusColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Text(
                                  report['reason'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
