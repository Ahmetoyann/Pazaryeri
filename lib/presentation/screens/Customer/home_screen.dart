import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/market_card.dart';
import '../../widgets/location_chip.dart';
import 'market_detail_screen.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';
import '../../viewmodels/notification_service.dart';
import 'notifications_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final langVM = context.watch<LanguageViewModel>();
    final authVM = context.watch<AuthViewModel>();

    List<Widget> _buildProvinceMarketsSlivers(HomeViewModel vm) {
      final filteredList = vm.filteredProvinceMarkets;

      if (vm.provinceMarkets.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '"${vm.selectedProvince}" ${langVM.translate('province_not_found')}',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      vm.clearProvinceSelection();
                      await vm.loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    child: Text(langVM.translate('clear_selection')),
                  ),
                ],
              ),
            ),
          ),
        ];
      }

      if (filteredList.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('${vm.selectedDay} günü açık pazar bulunamadı.'),
            ),
          )
        ];
      }

      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final m = filteredList[index];
                final tag = '${m.id}_prov';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MarketCard(
                    market: m,
                    heroTag: tag,
                    isHorizontal: false,
                    showOccupancy: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MarketDetailScreen(market: m, heroTag: tag),
                        ),
                      );
                    },
                  ),
                );
              },
              childCount: filteredList.length,
            ),
          ),
        ),
      ];
    }

    List<Widget> _buildNearbyMarketsSlivers(HomeViewModel vm) {
      final filteredList = vm.filteredNearbyMarkets;

      if (vm.nearbyMarkets.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vm.state == ViewState.busy
                        ? ''
                        : (vm.errorMessage ?? 'Yakında pazar bulunamadı.'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await vm.loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    child: Text(langVM.translate('retry')),
                  ),
                ],
              ),
            ),
          ),
        ];
      }

      if (filteredList.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('${vm.selectedDay} günü açık pazar bulunamadı.'),
            ),
          )
        ];
      }

      // Yatay liste için sadece ilk 5 pazarı alalım
      final horizontalList = filteredList.take(5).toList();
      final verticalList = filteredList;

      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  langVM.translate('nearby_markets'),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: horizontalList.length,
                    itemBuilder: (context, index) {
                      final market = horizontalList[index];
                      final tag = '${market.id}_hor';
                      return MarketCard(
                        market: market,
                        heroTag: tag,
                        showOccupancy: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MarketDetailScreen(
                                  market: market, heroTag: tag),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  langVM.translate('all_markets'),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final market = verticalList[index];
                final tag = '${market.id}_ver';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MarketCard(
                    market: market,
                    heroTag: tag,
                    isHorizontal: false,
                    showOccupancy: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MarketDetailScreen(market: market, heroTag: tag),
                        ),
                      );
                    },
                  ),
                );
              },
              childCount: verticalList.length,
            ),
          ),
        ),
      ];
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: Text(langVM.translate('home_title')),
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: authVM.currentUser != null
                ? AuthService.instance
                    .getUserNotifications(authVM.currentUser!.id)
                : null,
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount =
                    snapshot.data!.where((n) => n['read'] == false).length;
              }
              return IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.notifications),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: LocationChip(
              address: vm.currentAddress,
              onTap: () {
                if (vm.currentAddress != null) {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (context) => Container(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle bar (Tutma çubuğu)
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Başlık Alanı
                          Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                langVM.translate('location_title'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Bilgi Kartı
                          Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    context,
                                    Icons.map,
                                    '${vm.currentAddress!.neighborhood}, ${vm.currentAddress!.district}',
                                  ),
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    context,
                                    Icons.location_city,
                                    vm.currentAddress!.city,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Aksiyon Butonları
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await Geolocator.openLocationSettings();
                                  },
                                  icon: const Icon(Icons.settings),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                  ),
                                  label: Text(langVM.translate('settings')),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    vm.clearProvinceSelection();
                                    await vm.loadData();
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${langVM.translate('location_updated')}: ${vm.currentAddress?.city ?? langVM.translate('unknown')}',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.refresh),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: BorderSide(
                                          color: Colors.white.withOpacity(0.3)),
                                    ),
                                  ),
                                  label: Text(
                                    langVM.translate('location_refresh'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 110),
        child: CustomScrollView(
          slivers: [
            // Gün Filtreleri
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _days.length,
                        itemBuilder: (context, index) {
                          final day = _days[index];
                          final isSelected = vm.selectedDay == day;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: GestureDetector(
                              onTap: () {
                                vm.updateDayFilter(isSelected ? null : day);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(30),
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: Colors.white.withOpacity(0.3)),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            if (vm.state == ViewState.busy)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.state == ViewState.error)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${langVM.translate('error_prefix')}: ${vm.errorMessage}',
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await Geolocator.openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                        ),
                        child: Text(langVM.translate('settings')),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await Geolocator.openLocationSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                        ),
                        child: Text(langVM.translate('location_settings')),
                      ),
                    ],
                  ),
                ),
              )
            else if (vm.selectedProvince != null)
              ..._buildProvinceMarketsSlivers(vm)
            else
              ..._buildNearbyMarketsSlivers(vm),

            // Bottom padding for navigation bar
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
