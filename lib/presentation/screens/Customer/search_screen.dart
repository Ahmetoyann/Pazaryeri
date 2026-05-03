import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../data/models/market.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/market_card.dart';
import 'market_detail_screen.dart';
import '../../viewmodels/auth_service.dart';
import 'customer_seller_detail_screen.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/empty_state_view.dart';

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
  int _searchType = 0; // 0: Pazar, 1: Satıcı
  List<Map<String, dynamic>> _sellerResults = [];
  bool _isSearchingSellers = false;
  List<Market> _allMarkets = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadRecentSearches();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMarkets());
  }

  Future<void> _loadMarkets() async {
    try {
      final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
      final markets = await sellerVM.getMarkets();
      if (mounted) {
        setState(() {
          _allMarkets = markets;
        });
      }
    } catch (e) {
      debugPrint('Pazarlar yüklenemedi: $e');
    }
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

  Future<void> _performSellerSearch(String query) async {
    setState(() => _isSearchingSellers = true);
    final results = await AuthService.instance.searchAllSellers(query);

    if (results.isNotEmpty) {
      await Future.wait(results.map((seller) async {
        try {
          final stats = await AuthService.instance.getSellerStats(seller['id']);
          seller['rating'] = stats['averageRating'];
          seller['reviewCount'] = stats['reviewCount'];
        } catch (e) {
          debugPrint('Puan çekilemedi: $e');
        }
      }));
    }

    if (mounted) {
      setState(() {
        _sellerResults = results;
        _isSearchingSellers = false;
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
            if (_query.isNotEmpty && _searchType == 1) {
              _performSellerSearch(_query);
            }
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _searchController.text = val.recognizedWords;
              _query = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
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

        matchesQuery = nameMatch || districtMatch || neighborhoodMatch;
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

  // Saate göre dinamik doluluk oranı hesapla
  double _calculateDynamicOccupancy(String marketId) {
    final now = DateTime.now();
    final hour = now.hour;

    // Pazarın ID'sine göre tutarlı bir rastgelelik oluştur
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
    final homeVM = context.watch<HomeViewModel>();
    final langVM = context.watch<LanguageViewModel>();

    // HomeViewModel'deki tüm pazarları kaynak olarak kullanıyoruz.
    // Not: Gerçek senaryoda tüm pazarları çekmek için ayrı bir metod gerekebilir,
    // şimdilik nearbyMarkets ve provinceMarkets birleşimi veya repository'den tümünü çekmek mantıklı olabilir.
    // Burada örnek olarak nearbyMarkets kullanıyoruz.
    final sourceList = homeVM.nearbyMarkets;
    final results = _filterMarkets(sourceList);

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16),
      child: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: langVM.translate('search_placeholder'),
              onMicPressed: _listen,
              isListening: _isListening,
              onChanged: (val) {
                setState(() {
                  _query = val;
                });
                if (_searchType == 1) {
                  _performSellerSearch(val);
                }
              },
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  surfaceTintColor: Colors.transparent,
                  shape: const StadiumBorder(),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  labelStyle: const TextStyle(color: Colors.white),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Colors.white,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(langVM.translate('filter_weekend')),
                  selected: _filterWeekend,
                  onSelected: (val) => setState(() => _filterWeekend = val),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  surfaceTintColor: Colors.transparent,
                  shape: const StadiumBorder(),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  labelStyle: const TextStyle(color: Colors.white),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Kategori Sekmeleri (Pazar / Satıcı)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _searchType = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _searchType == 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: _searchType == 0
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          langVM.translate('market_tab'),
                          style: TextStyle(
                            color: _searchType == 0
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _searchType = 1);
                        _performSellerSearch(_query);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _searchType == 1
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: _searchType == 1
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          langVM.translate('seller_tab'),
                          style: TextStyle(
                            color: _searchType == 1
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Sonuç Listesi
          Expanded(
            child: _searchType == 0
                ? _buildMarketList(results, langVM)
                : _buildSellerList(langVM),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketList(List<Market> results, LanguageViewModel langVM) {
    if (_query.isEmpty && !_filterOpenToday && !_filterWeekend) {
      return Center(
        child: _recentSearches.isEmpty
            ? Text(
                langVM.translate('search_initial_message'),
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6)),
              )
            : _buildRecentSearchesList(langVM),
      );
    }
    return results.isEmpty
        ? EmptyStateView(
            iconData: Icons.search_off,
            title: langVM.translate('no_results'),
            message:
                'Aradığınız kelimeye uygun bir satıcı veya pazar bulunamadı.',
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final market = results[index];
              final tag = '${market.id}_search';

              // Gerçek doluluk oranı kullanımı
              final occupancy = _calculateDynamicOccupancy(market.id);
              Color statusColor;
              Color contentColor = Colors.white;
              IconData statusIcon;

              if (occupancy <= 0.25) {
                statusColor = Colors.white;
                contentColor = Colors.black;
                statusIcon = Icons.person_outline;
              } else if (occupancy <= 0.50) {
                statusColor = Colors.yellow;
                contentColor = Colors.black;
                statusIcon = Icons.person;
              } else if (occupancy <= 0.75) {
                statusColor = Colors.orange;
                statusIcon = Icons.people_outline;
              } else {
                statusColor = Colors.red;
                statusIcon = Icons.groups;
              }

              final statusText = '%${(occupancy * 100).toInt()}';

              return Stack(
                children: [
                  MarketCard(
                    market: market,
                    heroTag: tag,
                    isHorizontal: false,
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
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: contentColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: contentColor,
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
          );
  }

  Widget _buildSellerList(LanguageViewModel langVM) {
    if (_isSearchingSellers) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (_sellerResults.isEmpty) {
      return EmptyStateView(
        iconData: Icons.search_off,
        title: langVM.translate('no_results'),
        message: 'Aradığınız kelimeye uygun bir satıcı veya pazar bulunamadı.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sellerResults.length,
      itemBuilder: (context, index) {
        final seller = _sellerResults[index];
        final displayName = seller['stallName'] ??
            '${seller['firstName'] ?? ''} ${seller['lastName'] ?? ''}'.trim();
        final description = seller['stallDescription'] ?? '';
        final rating = (seller['rating'] as num?)?.toDouble() ?? 0.0;
        final reviewCount = (seller['reviewCount'] as num?)?.toInt() ?? 0;

        // Pazar ismini bul
        String marketName = '';
        final marketId = seller['sellerMarketId'];
        if (marketId != null && _allMarkets.isNotEmpty) {
          try {
            final market = _allMarkets.firstWhere((m) => m.id == marketId);
            marketName = market.name;
          } catch (_) {}
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage: (seller['profilePicture'] != null &&
                        seller['profilePicture'].isNotEmpty)
                    ? NetworkImage(seller['profilePicture'])
                    : null,
                child: (seller['profilePicture'] == null ||
                        seller['profilePicture'].isEmpty)
                    ? Icon(
                        Icons.people,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      )
                    : null,
              ),
              title: Text(displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (description.isNotEmpty)
                    Text(description,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (rating > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const SvgIcon(
                            iconPath: AppIcons.star,
                            size: 14,
                            color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount)',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (marketName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SvgIcon(
                            iconPath: AppIcons.market,
                            size: 14,
                            color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            marketName,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerSellerDetailScreen(
                      sellerId: seller['id'],
                      sellerName: displayName,
                      sellerDescription: description,
                      stallLocation: seller['stallLocation'] ?? '',
                      stallHours: seller['stallHours'] ?? '',
                      instagramLink: seller['instagramLink'],
                      facebookLink: seller['facebookLink'],
                      instagramName: seller['instagramName'],
                      facebookName: seller['facebookName'],
                      profilePicture: seller['profilePicture'],
                      marketName: marketName.isNotEmpty ? marketName : null,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
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
                leading: const SvgIcon(
                    iconPath: AppIcons.clock, size: 20, color: Colors.grey),
                title: Text(term),
                trailing: IconButton(
                  icon: const SvgIcon(
                      iconPath: AppIcons.close, size: 20, color: Colors.grey),
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
