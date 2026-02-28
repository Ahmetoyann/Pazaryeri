import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/market_card.dart';
import 'market_detail_screen.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/notification_service.dart';
import 'notifications_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';
import '../../widgets/side_menu_drawer.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  final List<String> _days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  final List<String> _dayKeys = [
    'day_monday',
    'day_tuesday',
    'day_wednesday',
    'day_thursday',
    'day_friday',
    'day_saturday',
    'day_sunday',
  ];

  Future<void> _openMapSearch(HomeViewModel vm) async {
    if (vm.currentAddress == null) return;

    final city = vm.currentAddress!.city;
    Uri uri;

    if (city.isNotEmpty) {
      // Şehirdeki tüm semt pazarlarını haritada göster
      final query = Uri.encodeComponent('$city Semt Pazarları');
      uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    } else {
      final lat = vm.currentAddress!.latitude;
      final lng = vm.currentAddress!.longitude;
      uri = Uri.parse(
          "https://www.google.com/maps/search/Semt+Pazarı/@$lat,$lng,14z");
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Harita açılamadı');
      }
    } catch (e) {
      debugPrint('Harita hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final langVM = context.watch<LanguageViewModel>();

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
                        borderRadius: BorderRadius.circular(12),
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
              child: Text(langVM.translate('no_open_market_found')),
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
                        : (vm.errorMessage ??
                            langVM.translate('no_nearby_markets')),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await vm.loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
              child: Text(langVM.translate('no_open_market_found')),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      langVM.translate('nearby_markets'),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    GestureDetector(
                      onTap: () => _openMapSearch(vm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        child: Text(
                          langVM.translate('see_all'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
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

    return Stack(
      children: [
        Padding(
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).padding.top + 80),
          child: CustomScrollView(
            slivers: [
              // İl ve İlçe Filtreleri
              if (vm.allCities.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        // İl Filtresi
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.5),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: vm.selectedCityFilter,
                                hint: Text(
                                  langVM.translate('select_city'),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                isExpanded: true,
                                icon: SvgIcon(
                                    iconPath: AppIcons.market,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                items: vm.allCities.map((String city) {
                                  return DropdownMenuItem<String>(
                                    value: city == 'Tümü' ? null : city,
                                    child: Text(city),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  vm.updateCityFilter(newValue);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // İlçe Filtresi
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: vm.selectedCityFilter == null
                                  ? Theme.of(context).cardColor.withOpacity(0.5)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: vm.selectedCityFilter == null
                                    ? Colors.grey.withOpacity(0.4)
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.5),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: vm.selectedDistrictFilter,
                                hint: Text(langVM.translate('select_district'),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6))),
                                isExpanded: true,
                                icon: SvgIcon(
                                    iconPath: AppIcons.map,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                items: vm.districtsForSelectedCity
                                    .map((String district) {
                                  return DropdownMenuItem<String>(
                                    value: district == 'Tümü' ? null : district,
                                    child: Text(district),
                                  );
                                }).toList(),
                                onChanged: vm.selectedCityFilter == null
                                    ? null
                                    : (String? newValue) {
                                        vm.updateDistrictFilter(newValue);
                                      },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Gün Filtreleri
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _days.length,
                        itemBuilder: (context, index) {
                          final day = _days[index];
                          final dayDisplay = langVM.translate(_dayKeys[index]);
                          final isSelected = vm.selectedDay == day;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: GestureDetector(
                              onTap: () {
                                vm.updateDayFilter(isSelected ? null : day);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  dayDisplay,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              if (vm.state == ViewState.busy)
                const SliverFillRemaining(
                  child: Center(child: CustomLoadingIndicator()),
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
                              borderRadius: BorderRadius.circular(12),
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
                              borderRadius: BorderRadius.circular(12),
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
        // Menü İkonu
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 0,
          right: 16,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(32)),
                ),
                child: IconButton(
                  icon: Icon(Icons.menu,
                      color: Theme.of(context).iconTheme.color),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (vm.currentAddress != null) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      CustomBottomSheets.showContent(
                        context: context,
                        title: langVM.translate('location_title'),
                        icon: Icons.location_pin,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Theme.of(context).cardColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    context,
                                    AppIcons.map,
                                    '${vm.currentAddress!.neighborhood}, ${vm.currentAddress!.district}',
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Divider(
                                        color: Theme.of(context)
                                            .dividerColor
                                            .withOpacity(0.2)),
                                  ),
                                  _buildInfoRow(
                                    context,
                                    AppIcons.market,
                                    vm.currentAddress!.city,
                                  ),
                                ],
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
                                    icon: SvgIcon(
                                        iconPath: AppIcons.settings,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      side: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.5)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      foregroundColor:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    label: Text(langVM.translate('settings')),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      vm.clearProvinceSelection();
                                      await vm.loadData();
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                        CustomSnackbars.showSuccess(
                                          context,
                                          '${langVM.translate('location_updated')}: ${vm.currentAddress?.city ?? langVM.translate('unknown')}',
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.refresh),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
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
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0),
                      ),
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
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                            CurvedAnimation(
                              parent: _pulseController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const SvgIcon(
                              iconPath: AppIcons.location,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                langVM.translate('location_title'),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                vm.currentAddress != null
                                    ? [
                                        vm.currentAddress!.city,
                                        vm.currentAddress!.district,
                                        vm.currentAddress!.neighborhood
                                      ].where((s) => s.isNotEmpty).join(', ')
                                    : langVM.translate('finding_location'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String iconPath, String text) {
    return Row(
      children: [
        SvgIcon(
            iconPath: iconPath,
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
