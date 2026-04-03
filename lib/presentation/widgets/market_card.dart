import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/market.dart';
import '../viewmodels/language_viewmodel.dart';
import '../../core/constants/app_icons.dart';
import '../../presentation/widgets/svg_icon.dart';

class MarketCard extends StatelessWidget {
  final Market market;
  final bool isHorizontal;
  final VoidCallback? onTap;
  final String? heroTag;
  final bool showOccupancy;

  const MarketCard({
    super.key,
    required this.market,
    this.onTap,
    this.isHorizontal = true,
    this.heroTag,
    this.showOccupancy = false,
  });

  Color _getOccupancyColor(double occupancy, ColorScheme colorScheme) {
    return colorScheme.primary;
  }

  // Saate göre dinamik doluluk oranı hesapla
  double _calculateDynamicOccupancy(String marketId) {
    final now = DateTime.now();
    final hour = now.hour;

    // Pazarın ID'sine göre tutarlı bir rastgelelik oluştur
    // Böylece her render'da değişmez ama her pazar için farklı olur
    final random = Random(marketId.hashCode + now.day);
    final baseRandom = random.nextDouble() * 0.2; // %0-20 arası rastgelelik

    // Saatlik baz doluluk oranları (0.0 - 1.0 arası)
    double baseOccupancy = 0.1;

    if (hour >= 8 && hour < 11)
      baseOccupancy = 0.3; // Sabah sakin
    else if (hour >= 11 && hour < 14)
      baseOccupancy = 0.7; // Öğle yoğun
    else if (hour >= 14 && hour < 17)
      baseOccupancy = 0.5; // Öğleden sonra normal
    else if (hour >= 17 && hour < 20)
      baseOccupancy = 0.8; // Akşam iş çıkışı yoğun
    else if (hour >= 20) baseOccupancy = 0.2; // Kapanışa doğru sakin

    // Rastgelelik ekle ve 0.0-1.0 arasına sıkıştır
    double finalOccupancy = (baseOccupancy + baseRandom).clamp(0.0, 1.0);
    return finalOccupancy;
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    String _todayTurkish() {
      final map = {
        1: 'Pazartesi',
        2: 'Salı',
        3: 'Çarşamba',
        4: 'Perşembe',
        5: 'Cuma',
        6: 'Cumartesi',
        7: 'Pazar',
      };
      return map[DateTime.now().weekday]!;
    }

    final today = _todayTurkish();
    final isOpenToday = market.openDays.contains(today);

    // Saat kontrolü: 05:00 - 20:30
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = 5 * 60; // 05:00
    final endMinutes = 20 * 60 + 30; // 20:30
    final isBeforeOpening = isOpenToday && currentMinutes < startMinutes;
    final isOpenNow = isOpenToday &&
        currentMinutes >= startMinutes &&
        currentMinutes <= endMinutes;

    final baseTag = heroTag ?? market.id;

    // Dinamik doluluk oranı
    final dynamicOccupancy = _calculateDynamicOccupancy(market.id);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: isHorizontal ? size.width * 0.6 : null,
          height: isHorizontal ? 170 : null,
          margin: EdgeInsets.symmetric(
            horizontal: isHorizontal ? 12 : 0,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isHorizontal ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Icon + Name + Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'market_icon_$baseTag',
                      child: Container(
                          padding: EdgeInsets.all(isHorizontal ? 8 : 10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.storefront,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'market_name_$baseTag',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                market.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              SvgIcon(
                                  iconPath: AppIcons.location,
                                  size: 14,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7)),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  '${market.address.neighborhood}, ${market.address.district}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (showOccupancy) ...[
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: dynamicOccupancy),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Row(
                        children: [
                          Icon(Icons.people_alt_outlined,
                              size: 16,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7)),
                          const SizedBox(width: 6),
                          Text(
                            langVM.translate('occupancy_rate'),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor:
                                    theme.dividerColor.withOpacity(0.1),
                                color: _getOccupancyColor(
                                    dynamicOccupancy, theme.colorScheme),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '%${(value * 100).toInt()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getOccupancyColor(
                                  dynamicOccupancy, theme.colorScheme),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],

                if (isHorizontal)
                  const Spacer()
                else
                  const SizedBox(height: 12),

                if (!isHorizontal) ...[
                  Text(
                    market.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Footer: Status & Distance
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isBeforeOpening
                            ? Colors.orange.withOpacity(0.1)
                            : (isOpenNow
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isBeforeOpening
                                  ? Colors.orange
                                  : (isOpenNow ? Colors.green : Colors.red),
                              shape: BoxShape.circle,
                            ),
                            child: SvgIcon(
                              iconPath: isBeforeOpening
                                  ? AppIcons.clock
                                  : (isOpenNow
                                      ? AppIcons.check
                                      : AppIcons.close),
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isBeforeOpening
                                ? "05.00'te kurulacak"
                                : (isOpenNow
                                    ? langVM.translate('market_open_today')
                                    : langVM.translate('market_closed_today')),
                            style: TextStyle(
                              color: isBeforeOpening
                                  ? Colors.orange
                                  : (isOpenNow ? Colors.green : Colors.red),
                              fontSize: isBeforeOpening ? 9 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        '${(market.distanceInMeters / 1000).toStringAsFixed(1)} km',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
