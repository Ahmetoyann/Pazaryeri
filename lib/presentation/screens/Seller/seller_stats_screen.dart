import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';

class SellerStatsScreen extends StatelessWidget {
  const SellerStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sellerVM = Provider.of<SellerViewModel>(context);
    final langVM = Provider.of<LanguageViewModel>(context);
    final theme = Theme.of(context);

    // Verileri Hazırla
    final products = sellerVM.myProducts;
    final totalViews =
        products.fold<int>(0, (sum, item) => sum + item.viewCount);
    final totalSales =
        products.fold<double>(0.0, (sum, item) => sum + item.salesCount);
    final totalRevenue = products.fold<double>(
        0.0, (sum, item) => sum + (item.salesCount * item.price));

    // En çok görüntülenen 5 ürünü al
    final topProducts = List<SellerProduct>.from(products)
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    final chartData = topProducts.take(5).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet Kartları
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: langVM.translate('total_views'),
                    value: totalViews.toString(),
                    icon: Icons.visibility,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: langVM.translate('total_sales'),
                    value: totalSales % 1 == 0
                        ? totalSales.toInt().toString()
                        : totalSales.toStringAsFixed(1),
                    icon: Icons.shopping_cart,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: langVM.translate('total_products'),
                    value: products.length.toString(),
                    icon: Icons.inventory_2,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: langVM.translate('total_revenue'),
                    value: '${totalRevenue.toStringAsFixed(2)} ₺',
                    icon: Icons.monetization_on,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Grafik Başlığı
            Text(
              langVM.translate('most_viewed'),
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Grafik Alanı
            if (chartData.isNotEmpty && totalViews > 0)
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (chartData.first.viewCount.toDouble() * 1.2).clamp(
                        10.0, double.infinity), // En yüksek değerin %20 fazlası
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) =>
                            theme.colorScheme.inverseSurface,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${chartData[group.x.toInt()].name}\n',
                            TextStyle(
                              color: theme.colorScheme.onInverseSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: (rod.toY - 1).toInt().toString(),
                                style: TextStyle(
                                  color: theme.colorScheme.inversePrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() >= chartData.length)
                              return const SizedBox();
                            // Ürün isminin ilk 4 harfini ve görüntülenme sayısını göster
                            final product = chartData[value.toInt()];
                            final name = product.name;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name.length > 4
                                        ? '${name.substring(0, 4)}..'
                                        : name,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    product.viewCount.toString(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            );
                          },
                          reservedSize: 50,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: chartData.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.viewCount.toDouble() +
                                0.1, // 0 ise bile çok az görünsün
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.5),
                                theme.colorScheme.primary,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(langVM.translate('no_stats_data'),
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6))),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6))),
        ],
      ),
    );
  }
}
