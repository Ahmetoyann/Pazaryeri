import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/market.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/market_card.dart';
import 'market_detail_screen.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/custom_app_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _filterOpenToday = true;
  bool _filterWeekend = false;
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final searches = await AuthService.instance.getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = searches;
      });
    }
  }

  Future<void> _addToHistory(String val) async {
    if (val.trim().isEmpty) return;
    await AuthService.instance.addRecentSearch(val);
    await _loadRecentSearches();
  }

  Future<void> _removeFromHistory(String val) async {
    await AuthService.instance.removeRecentSearch(val);
    await _loadRecentSearches();
  }

  Future<void> _clearHistory() async {
    await AuthService.instance.clearRecentSearches();
    await _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Arama mantığı
  List<Market> _filterMarkets(List<Market> allMarkets) {
    if (_query.isEmpty && !_filterOpenToday && !_filterWeekend) {
      return [];
    }

    final lowerQuery = _query.toLowerCase();
    final todayIndex = DateTime.now().weekday;
    final daysMap = {
      1: 'Pazartesi',
      2: 'Salı',
      3: 'Çarşamba',
      4: 'Perşembe',
      5: 'Cuma',
      6: 'Cumartesi',
      7: 'Pazar',
    };
    final todayName = daysMap[todayIndex];

    return allMarkets.where((market) {
      // 1. Metin Araması
      bool matchesQuery = true;
      if (_query.isNotEmpty) {
        final nameMatch = market.name.toLowerCase().contains(lowerQuery);
        final districtMatch = market.address.district.toLowerCase().contains(
              lowerQuery,
            );
        final neighborhoodMatch =
            market.address.neighborhood.toLowerCase().contains(lowerQuery);
        // Ürünlerde arama
        final productMatch = market.products.any(
          (p) => p.toLowerCase().contains(lowerQuery),
        );

        matchesQuery =
            nameMatch || districtMatch || neighborhoodMatch || productMatch;
      }

      // 2. "Bugün Açık" Filtresi
      bool matchesOpenToday = true;
      if (_filterOpenToday) {
        matchesOpenToday = market.openDays.contains(todayName);
      }

      // 3. "Hafta Sonu" Filtresi
      bool matchesWeekend = true;
      if (_filterWeekend) {
        matchesWeekend = market.openDays.contains('Cumartesi') ||
            market.openDays.contains('Pazar');
      }

      return matchesQuery && matchesOpenToday && matchesWeekend;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();
    final langVM = context.watch<LanguageViewModel>();

    // HomeViewModel'deki tüm pazarları kaynak olarak kullanıyoruz.
    // Not: Gerçek senaryoda tüm pazarları çekmek için ayrı bir metod gerekebilir,
    // şimdilik nearbyMarkets ve provinceMarkets birleşimi veya repository'den tümünü çekmek mantıklı olabilir.
    // Burada örnek olarak nearbyMarkets kullanıyoruz.
    final sourceList = homeVM.nearbyMarkets;
    final results = _filterMarkets(sourceList);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: Text(langVM.translate('search_tab'))),
      body: Padding(
        padding: const EdgeInsets.only(top: 110),
        child: Column(
          children: [
            // Arama Çubuğu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _query = val;
                  });
                },
                onSubmitted: (val) {
                  _addToHistory(val);
                },
                decoration: InputDecoration(
                  labelText: langVM.translate('search_placeholder'),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(36),
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(129, 255, 255, 255),
                ),
              ),
            ),

            // Filtre Chip'leri
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(langVM.translate('filter_open_today')),
                    selected: _filterOpenToday,
                    onSelected: (val) => setState(() => _filterOpenToday = val),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(langVM.translate('filter_weekend')),
                    selected: _filterWeekend,
                    onSelected: (val) => setState(() => _filterWeekend = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Sonuç Listesi
            Expanded(
              child: (_query.isEmpty && !_filterOpenToday && !_filterWeekend)
                  ? Center(
                      child: _recentSearches.isEmpty
                          ? Text(
                              langVM.translate('search_initial_message'),
                              style: const TextStyle(color: Colors.grey),
                            )
                          : _buildRecentSearchesList(langVM),
                    )
                  : results.isEmpty
                      ? Center(child: Text(langVM.translate('no_results')))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: results.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final market = results[index];

                            // Doluluk oranı simülasyonu (Gerçek veride API'den gelmeli)
                            final occupancyLevel = market.id.hashCode % 3;
                            Color statusColor;
                            IconData statusIcon;
                            String statusText;

                            switch (occupancyLevel) {
                              case 0:
                                statusColor = Colors.green;
                                statusIcon = Icons.person_outline;
                                statusText = '%25'; // Tenha
                                break;
                              case 1:
                                statusColor = Colors.orange;
                                statusIcon = Icons.people_outline;
                                statusText = '%60'; // Normal
                                break;
                              case 2:
                              default:
                                statusColor = Colors.red;
                                statusIcon = Icons.groups;
                                statusText = '%95'; // Kalabalık
                                break;
                            }

                            return Stack(
                              children: [
                                MarketCard(
                                  market: market,
                                  isHorizontal: false,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MarketDetailScreen(market: market),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon,
                                            size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchesList(LanguageViewModel langVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                langVM.translate('recent_searches'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: _clearHistory,
                child: Text(langVM.translate('clear_history')),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final term = _recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(term),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => _removeFromHistory(term),
                ),
                onTap: () {
                  _searchController.text = term;
                  setState(() {
                    _query = term;
                  });
                  _addToHistory(term); // Tıklandığında tekrar başa al
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
