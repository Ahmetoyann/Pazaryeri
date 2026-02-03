import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/market.dart';
import '../viewmodels/language_viewmodel.dart';

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

  Color _getOccupancyColor(double occupancy) {
    if (occupancy <= 0.4) return Colors.green;
    if (occupancy <= 0.7) return Colors.orange;
    return Colors.red;
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

    final baseTag = heroTag ?? market.id;

    return GestureDetector(
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
            color: theme.dividerColor.withOpacity(0.05),
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
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: theme.colorScheme.primary,
                        size: isHorizontal ? 20 : 24,
                      ),
                    ),
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
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${market.address.neighborhood}, ${market.address.district}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
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
                Row(
                  children: [
                    Icon(Icons.people_alt_outlined,
                        size: 16, color: theme.hintColor),
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
                          value: market.occupancy,
                          backgroundColor: theme.dividerColor.withOpacity(0.1),
                          color: _getOccupancyColor(market.occupancy),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '%${(market.occupancy * 100).toInt()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getOccupancyColor(market.occupancy),
                      ),
                    ),
                  ],
                ),
              ],

              if (isHorizontal) const Spacer() else const SizedBox(height: 12),

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
                      color: isOpenToday
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOpenToday
                              ? Icons.check_circle
                              : Icons.access_time_filled,
                          size: 14,
                          color: isOpenToday ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOpenToday
                              ? langVM.translate('market_open_today')
                              : langVM.translate('market_closed_today'),
                          style: TextStyle(
                            color: isOpenToday ? Colors.green : Colors.red,
                            fontSize: 12,
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
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      '${(market.distanceInMeters / 1000).toStringAsFixed(1)} km',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
