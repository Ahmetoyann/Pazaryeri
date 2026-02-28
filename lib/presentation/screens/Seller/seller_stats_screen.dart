import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';

class SellerStatsScreen extends StatefulWidget {
  const SellerStatsScreen({super.key});

  @override
  State<SellerStatsScreen> createState() => _SellerStatsScreenState();
}

class _SellerStatsScreenState extends State<SellerStatsScreen> {
  final GlobalKey _soldChartKey = GlobalKey();
  int _touchedIndex = -1;
  int _stockTouchedIndex = -1;
  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _startAnimation = true);
      // İstatistiklerin güncel olması için ürünleri yeniden yükle
      Provider.of<SellerViewModel>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sellerVM = Provider.of<SellerViewModel>(context);
    final langVM = Provider.of<LanguageViewModel>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Verileri Hazırla
    final products = sellerVM.myProducts;
    final totalViews =
        products.fold<int>(0, (sum, item) => sum + item.viewCount);
    final totalSalesProductCount =
        products.where((p) => p.salesCount > 0).length;
    final totalRevenue = products.fold<double>(
        0.0, (sum, item) => sum + (item.salesCount * item.price));

    // En çok görüntülenen 5 ürünü al
    final topProducts = List<SellerProduct>.from(products)
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    final chartData = topProducts.take(5).toList();

    final topSoldProducts = List<SellerProduct>.from(products)
      ..sort(
          (a, b) => (b.salesCount * b.price).compareTo(a.salesCount * a.price));
    final soldChartData = topSoldProducts.take(5).toList();

    // Stok Durumu Verileri
    final outOfStockCount = products.where((p) => p.stockQuantity <= 0).length;
    final lowStockCount = products
        .where((p) => p.stockQuantity > 0 && p.stockQuantity <= 20)
        .length;
    final highStockCount = products.where((p) => p.stockQuantity > 20).length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
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
                    title: langVM.translate('total_sales_product'),
                    value: totalSalesProductCount.toString(),
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

            // Görüntülenme Grafiği
            if (chartData.isNotEmpty && totalViews > 0) ...[
              Text(
                langVM.translate('most_viewed'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                key: _soldChartKey,
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? theme.cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < chartData.length) {
                              final product = chartData[index];
                              final name = product.name;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  name.length > 4
                                      ? '${name.substring(0, 4)}..'
                                      : name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox();
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (chartData.length - 1).toDouble(),
                    minY: 0,
                    maxY: (chartData.first.viewCount.toDouble() * 1.2)
                        .clamp(10.0, double.infinity),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData.asMap().entries.map((e) {
                          return FlSpot(
                              e.key.toDouble(), e.value.viewCount.toDouble());
                        }).toList(),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF23B6E6),
                            Color(0xFF02D39A),
                          ],
                        ),
                        barWidth: 5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: theme.cardColor,
                              strokeWidth: 3,
                              strokeColor: const Color(0xFF23B6E6),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF23B6E6).withOpacity(0.3),
                              const Color(0xFF02D39A).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) =>
                            theme.colorScheme.inverseSurface,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final index = barSpot.x.toInt();
                            if (index < 0 || index >= chartData.length)
                              return null;
                            final product = chartData[index];
                            return LineTooltipItem(
                              '${product.name}\n',
                              TextStyle(
                                color: theme.colorScheme.onInverseSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: '${product.viewCount}',
                                  style: TextStyle(
                                    color: theme.colorScheme.inversePrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                ),
              )
            ],

            // Satış Grafiği (Pasta Grafiği)
            if (soldChartData.isNotEmpty && totalSalesProductCount > 0) ...[
              const SizedBox(height: 32),
              Text(
                langVM.translate('most_sold'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? theme.cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections:
                                  List.generate(soldChartData.length, (i) {
                                final isTouched = i == _touchedIndex;
                                final fontSize = isTouched ? 16.0 : 12.0;
                                final radius = isTouched ? 60.0 : 50.0;
                                final product = soldChartData[i];
                                const colors = [
                                  Color(0xFF26E5FF),
                                  Color(0xFFFFCF26),
                                  Color(0xFFEE2727),
                                  Color(0xFF61D800),
                                  Color(0xFF8B35FF),
                                ];
                                return PieChartSectionData(
                                  color: colors[i % colors.length],
                                  value: _startAnimation
                                      ? (product.salesCount * product.price)
                                      : 0.001,
                                  title: _startAnimation
                                      ? '${(product.salesCount * product.price).toStringAsFixed(0)}₺'
                                      : '',
                                  radius: radius,
                                  titleStyle: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(color: Colors.black, blurRadius: 2)
                                    ],
                                  ),
                                );
                              }),
                            ),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOutQuart,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Toplam',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              Text(
                                '${totalRevenue.toStringAsFixed(0)}₺',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(soldChartData.length, (i) {
                        const colors = [
                          Color(0xFF26E5FF),
                          Color(0xFFFFCF26),
                          Color(0xFFEE2727),
                          Color(0xFF61D800),
                          Color(0xFF8B35FF),
                        ];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors[i % colors.length],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  soldChartData[i].name,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],

            // Stok Durumu Grafiği
            if (products.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                langVM.translate('stock_distribution_title'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _stockTouchedIndex = -1;
                                  return;
                                }
                                _stockTouchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            _buildStockSection(
                                0,
                                highStockCount,
                                langVM.translate('stock_high'),
                                const Color(0xFF00E676)),
                            _buildStockSection(
                                1,
                                lowStockCount,
                                langVM.translate('stock_low'),
                                const Color(0xFFFFAB40)),
                            _buildStockSection(
                                2,
                                outOfStockCount,
                                langVM.translate('stock_out'),
                                const Color(0xFFFF5252)),
                          ],
                        ),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutQuart,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(const Color(0xFF00E676),
                            langVM.translate('legend_stock_high')),
                        const SizedBox(height: 8),
                        _buildLegendItem(const Color(0xFFFFAB40),
                            langVM.translate('legend_stock_low')),
                        const SizedBox(height: 8),
                        _buildLegendItem(const Color(0xFFFF5252),
                            langVM.translate('legend_stock_out')),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (totalViews == 0 && totalSalesProductCount == 0)
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

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(value,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PieChartSectionData _buildStockSection(
      int index, int value, String title, Color color) {
    final isTouched = index == _stockTouchedIndex;
    final fontSize = isTouched ? 16.0 : 12.0;
    final radius = isTouched ? 60.0 : 50.0;

    return PieChartSectionData(
      color: color,
      value: _startAnimation ? value.toDouble() : 0.001,
      title: _startAnimation ? '$value' : '',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // --- Aksiyon Metotları ---

  void _showViewersSheet(BuildContext context, ThemeData theme) {
    final currentUserId = AuthService.instance.currentUserId;
    if (currentUserId == null) return;
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    CustomBottomSheets.showDraggable(
      context: context,
      initialChildSize: 0.6,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(langVM.translate('recent_viewers_title'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future:
                  AuthService.instance.getRecentProductViewers(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final viewers = snapshot.data ?? [];
                if (viewers.isEmpty) {
                  return Center(
                      child: Text(langVM.translate('no_viewers_yet')));
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: viewers.length,
                  itemBuilder: (context, index) {
                    final viewer = viewers[index];
                    final timestamp = viewer['timestamp'];
                    String timeStr = '';
                    if (timestamp is Timestamp) {
                      final date = timestamp.toDate();
                      timeStr =
                          '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                    }

                    final rawName = viewer['userName'] as String?;
                    final userName = (rawName != null && rawName.isNotEmpty)
                        ? rawName
                        : 'Misafir';
                    final productName = viewer['productName'] ??
                        langVM.translate('product_default');
                    final userImage = viewer['userImage'];

                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          if (userImage != null && userImage.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  backgroundColor: Colors.black,
                                  appBar: AppBar(
                                    backgroundColor: Colors.black,
                                    iconTheme: const IconThemeData(
                                        color: Colors.white),
                                  ),
                                  body: Center(
                                    child: InteractiveViewer(
                                      child: Image.network(
                                        userImage,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.2),
                          backgroundImage:
                              (userImage != null && userImage.isNotEmpty)
                                  ? NetworkImage(userImage)
                                  : null,
                          child: (userImage == null || userImage.isEmpty)
                              ? Text(userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : '?')
                              : null,
                        ),
                      ),
                      title: Text(userName),
                      subtitle: Text(
                          '$productName ${langVM.translate('viewed_suffix')}'),
                      trailing: Text(timeStr,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToSoldChart() {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    if (_soldChartKey.currentContext != null) {
      Scrollable.ensureVisible(
        _soldChartKey.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.5, // Ortala
      );
    } else {
      CustomSnackbars.showInfo(
        context,
        langVM.translate('no_sales_chart_data'),
      );
    }
  }

  void _showProductsSheet(
      BuildContext context, ThemeData theme, List<SellerProduct> products) {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    CustomBottomSheets.showDraggable(
      context: context,
      initialChildSize: 0.6,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(langVM.translate('product_list_title'),
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  leading: const Icon(Icons.shopping_basket),
                  title: Text(product.name),
                  subtitle: Text('${product.price} ₺ / ${product.unit}'),
                  trailing: Text('Stok: ${product.stockQuantity.toInt()}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRevenueCalculationSheet(
      BuildContext context, ThemeData theme, List<SellerProduct> products) {
    final soldProducts = products.where((p) => p.salesCount > 0).toList();
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    CustomBottomSheets.showDraggable(
      context: context,
      initialChildSize: 0.6,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(langVM.translate('revenue_calculation_title'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: soldProducts.isEmpty
                ? Center(child: Text(langVM.translate('no_sales_revenue_yet')))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: soldProducts.length,
                    itemBuilder: (context, index) {
                      final product = soldProducts[index];
                      final revenue = product.salesCount * product.price;
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                            '${product.salesCount.toInt()} ${langVM.translate('pieces_x')} ${product.price} ₺'),
                        trailing: Text(
                          '${revenue.toStringAsFixed(2)} ₺',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
