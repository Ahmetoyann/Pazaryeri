import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../../core/regions/provinces.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/market_card.dart';
import '../../widgets/location_chip.dart';
import 'market_detail_screen.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';

// A simple Levenshtein distance implementation for fuzzy matching
int _levenshtein(String s, String t) {
  final lenS = s.length;
  final lenT = t.length;
  if (lenS == 0) return lenT;
  if (lenT == 0) return lenS;
  final v0 = List<int>.generate(lenT + 1, (i) => i);
  final v1 = List<int>.filled(lenT + 1, 0);
  for (var i = 0; i < lenS; i++) {
    v1[0] = i + 1;
    for (var j = 0; j < lenT; j++) {
      final cost = s[i] == t[j] ? 0 : 1;
      v1[j + 1] = [
        v1[j] + 1,
        v0[j + 1] + 1,
        v0[j] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
    for (var j = 0; j <= lenT; j++) {
      v0[j] = v1[j];
    }
  }
  return v1[lenT];
}

double _similarity(String a, String b) {
  if (a == b) return 1.0;
  if (a.startsWith(b)) return 0.95;
  if (a.contains(b)) return 0.8;
  final dist = _levenshtein(a, b);
  final maxLen = a.length > b.length ? a.length : b.length;
  if (maxLen == 0) return 0.0;
  final score = 1.0 - (dist / maxLen);
  return score.clamp(0.0, 1.0);
}

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

    Widget _buildProvinceMarketsList(HomeViewModel vm) {
      final filteredList = vm.filteredProvinceMarkets;

      if (vm.provinceMarkets.isEmpty) {
        return Center(
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
                child: Text(langVM.translate('clear_selection')),
              ),
            ],
          ),
        );
      }

      if (filteredList.isEmpty) {
        return Center(
          child: Text('${vm.selectedDay} günü açık pazar bulunamadı.'),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredList.length,
        separatorBuilder: (c, i) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final m = filteredList[index];
          return MarketCard(
            market: m,
            isHorizontal: false,
            showOccupancy: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MarketDetailScreen(market: m),
                ),
              );
            },
          );
        },
      );
    }

    Widget _buildNearbyMarketsList(HomeViewModel vm) {
      final filteredList = vm.filteredNearbyMarkets;

      if (vm.nearbyMarkets.isEmpty) {
        return Center(
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
                child: Text(langVM.translate('retry')),
              ),
            ],
          ),
        );
      }

      if (filteredList.isEmpty) {
        return Center(
          child: Text('${vm.selectedDay} günü açık pazar bulunamadı.'),
        );
      }

      // Yatay liste için sadece ilk 5 pazarı alalım
      final horizontalList = filteredList.take(5).toList();

      // Dikey liste için tüm pazarları (veya yatay listeden sonrasını) alabiliriz
      // Şimdilik tümünü gösterelim.
      final verticalList = filteredList;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            langVM.translate('nearby_markets'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height:
                240, // MarketCard yüksekliğine göre ayarlandı (gölgeler için pay bırakıldı)
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
                        builder: (context) =>
                            MarketDetailScreen(market: market, heroTag: tag),
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: verticalList.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final market = verticalList[index];
                final tag = '${market.id}_ver';
                return MarketCard(
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
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: Text(langVM.translate('home_title')),
        actions: [
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
                                color: Colors.green,
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
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.1),
                              ),
                            ),
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
                                  label: Text(langVM.translate('settings')),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
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
                                  label: Text(
                                    langVM.translate('location_refresh'),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
        padding: const EdgeInsets.fromLTRB(12, 110, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.selectedProvince != null) ...[
              Text(
                '${langVM.translate('selected_province')}: ${vm.selectedProvince}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Province filter (Autocomplete)
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final query = textEditingValue.text.trim();
                      if (query.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      // Score provinces using a simple fuzzy similarity
                      final q = query.toLowerCase();
                      final scored = kTurkishProvinces
                          .map(
                            (p) => MapEntry(p, _similarity(p.toLowerCase(), q)),
                          )
                          .where((e) => e.value > 0.2)
                          .toList();
                      // Sort by score descending and return top 12 suggestions
                      scored.sort((a, b) => b.value.compareTo(a.value));
                      return scored.take(12).map((e) => e.key);
                    },
                    onSelected: (selection) async {
                      await vm.loadMarketsForProvince(selection);
                    },
                    fieldViewBuilder: (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: langVM.translate(
                            'search_province_hint',
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            borderRadius: BorderRadius.circular(36),
                          ),
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(36),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (vm.selectedProvince != null)
                  ElevatedButton(
                    onPressed: () async {
                      vm.clearProvinceSelection();
                      await vm.loadData();
                    },
                    child: Text(langVM.translate('clear_selection')),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Gün Filtreleri
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _days.map((day) {
                  final isSelected = vm.selectedDay == day;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(day),
                      selected: isSelected,
                      onSelected: (selected) {
                        vm.updateDayFilter(selected ? day : null);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            if (vm.state == ViewState.busy) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (vm.state == ViewState.error) ...[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${langVM.translate('error_prefix')}: ${vm.errorMessage}',
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        // Offer the user to open app settings for enabling location
                        await Geolocator.openAppSettings();
                      },
                      child: Text(langVM.translate('settings')),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await Geolocator.openLocationSettings();
                      },
                      child: Text(langVM.translate('location_settings')),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: vm.selectedProvince != null
                    ? _buildProvinceMarketsList(vm)
                    : _buildNearbyMarketsList(vm),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
