import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../../data/models/market.dart';
import 'my_reports_screen.dart';
import 'report_form_screen.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/svg_icon.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';

class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});

  void _showMarketSelection(BuildContext context, {required bool isForSeller}) {
    if (isForSeller) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const _SellerReportSelectionScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const _MarketSelectionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Row(
            children: [
              Expanded(
                child: _buildOptionCard(
                  context,
                  title: langVM.translate('report_seller_option'),
                  icon: Icons.people,
                  color: Colors.orange,
                  onTap: () => _showMarketSelection(context, isForSeller: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOptionCard(
                  context,
                  title: langVM.translate('report_market_option'),
                  icon: Icons.storefront,
                  color: Colors.blue,
                  onTap: () =>
                      _showMarketSelection(context, isForSeller: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _buildOptionCard(
              context,
              title: langVM.translate('report_history'),
              icon: Icons.history,
              color: Colors.purple,
              height: 150,
              iconSize: 36,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyReportsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double height = 200,
    double iconSize = 48,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Stack(
              children: [
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.arrow_outward,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                    size: 24,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: iconSize, color: color),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketSelectionScreen extends StatefulWidget {
  const _MarketSelectionScreen({super.key});

  @override
  State<_MarketSelectionScreen> createState() => _MarketSelectionScreenState();
}

class _MarketSelectionScreenState extends State<_MarketSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String? _selectedCity;
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
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
              _searchQuery = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();
    final homeVM = context.watch<HomeViewModel>();

    final nearbyMarketIds = homeVM.nearbyMarkets.map((m) => m.id).toSet();
    final allMarkets =
        <Market>{...homeVM.nearbyMarkets, ...homeVM.provinceMarkets}.toList();

    final cities = allMarkets.map((m) => m.address.city).toSet().toList()
      ..sort();

    List<String> districts = [];
    if (_selectedCity != null) {
      districts = allMarkets
          .where((m) => m.address.city == _selectedCity)
          .map((m) => m.address.district)
          .toSet()
          .toList()
        ..sort();
    }

    final marketList = allMarkets.where((m) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = m.name.toLowerCase().contains(query) ||
          m.address.district.toLowerCase().contains(query) ||
          m.address.city.toLowerCase().contains(query);
      final matchesCity =
          _selectedCity == null || m.address.city == _selectedCity;
      final matchesDistrict =
          _selectedDistrict == null || m.address.district == _selectedDistrict;
      return matchesSearch && matchesCity && matchesDistrict;
    }).toList();

    // Sıralama: Yakındakiler en üstte, sonra alfabetik
    marketList.sort((a, b) {
      final isANearby = nearbyMarketIds.contains(a.id);
      final isBNearby = nearbyMarketIds.contains(b.id);

      if (isANearby && !isBNearby) return -1;
      if (!isANearby && isBNearby) return 1;
      if (isANearby && isBNearby) {
        return a.distanceInMeters.compareTo(b.distanceInMeters);
      }
      return a.name.compareTo(b.name);
    });

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(langVM.translate('select_market_to_report')),
      ),
      body: Container(
        child: Column(
          children: [
            if (cities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        context,
                        hint: langVM.translate('city'),
                        value: _selectedCity,
                        items: cities,
                        onChanged: (val) {
                          setState(() {
                            _selectedCity = val;
                            _selectedDistrict = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        context,
                        hint: 'İlçe',
                        value: _selectedDistrict,
                        items: districts,
                        onChanged: (val) {
                          setState(() {
                            _selectedDistrict = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CustomSearchBar(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                hintText: langVM.translate('search_placeholder'),
                onMicPressed: _listen,
                isListening: _isListening,
              ),
            ),
            Expanded(
              child: marketList.isEmpty
                  ? Center(child: Text(langVM.translate('no_results')))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: marketList.length,
                      itemBuilder: (context, index) {
                        final market = marketList[index];
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Theme.of(context).cardColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              leading: Icon(
                                nearbyMarketIds.contains(market.id)
                                    ? Icons.near_me
                                    : Icons.location_on_outlined,
                                color: nearbyMarketIds.contains(market.id)
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              title: Text(
                                market.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  '${market.address.district}, ${market.address.city} • ${(market.distanceInMeters / 1000).toStringAsFixed(1)} km'),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: _AnimatedArrowIcon(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportFormScreen(
                                      marketId: market.id,
                                      marketName: market.name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style:
                  TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Tümü',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
            ...items.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SellerReportSelectionScreen extends StatefulWidget {
  const _SellerReportSelectionScreen();

  @override
  State<_SellerReportSelectionScreen> createState() =>
      _SellerReportSelectionScreenState();
}

class _SellerReportSelectionScreenState
    extends State<_SellerReportSelectionScreen> {
  Market? _selectedMarket;
  final TextEditingController _marketController = TextEditingController();
  List<Market> _markets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeVM = Provider.of<HomeViewModel>(context, listen: false);
      final markets =
          <Market>{...homeVM.nearbyMarkets, ...homeVM.provinceMarkets}.toList();
      markets.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _markets = markets;
      });
    });
  }

  @override
  void dispose() {
    _marketController.dispose();
    super.dispose();
  }

  void _showMarketPicker() {
    CustomBottomSheets.showDraggable(
      context: context,
      initialChildSize: 0.7,
      builder: (context, scrollController) {
        return _MarketPickerSheet(
          markets: _markets,
          scrollController: scrollController,
          onSelect: (market) {
            setState(() {
              _selectedMarket = market;
              _marketController.text = market.name;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    return Scaffold(
      appBar:
          CustomAppBar(title: Text(langVM.translate('report_seller_option'))),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            CustomTextField(
              controller: _marketController,
              readOnly: true,
              onTap: _showMarketPicker,
              labelText: 'Pazar Yeri Seçiniz',
              hintText: 'Pazar yeri aramak için dokunun',
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedMarket == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront,
                              size: 64, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'Lütfen önce pazar yeri seçiniz.',
                            style:
                                TextStyle(color: Colors.grey.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    )
                  : _SellerList(market: _selectedMarket!),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerList extends StatelessWidget {
  final Market market;
  const _SellerList({required this.market});

  @override
  Widget build(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                langVM.translate('select_seller_to_report'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: AuthService.instance.getMarketSellers(market.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CustomLoadingIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text(
                        '${langVM.translate('error_prefix')}: ${snapshot.error}'));
              }

              final sellers = snapshot.data ?? [];

              if (sellers.isEmpty) {
                return Center(
                  child: Text(langVM.translate('no_sellers_found')),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 16), // Çift boşluğu önlemek için padding ayarlandı
                itemCount: sellers.length,
                itemBuilder: (context, index) {
                  final seller = sellers[index];
                  String displayName = seller['stallName'] ?? '';
                  if (displayName.isEmpty) {
                    displayName =
                        '${seller['firstName'] ?? ''} ${seller['lastName'] ?? ''}'
                            .trim();
                  }
                  final profilePic = seller['profilePicture'];

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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportFormScreen(
                                marketId: market.id,
                                marketName: market.name,
                                sellerId: seller['id'],
                                sellerName: displayName,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  image: (profilePic != null &&
                                          profilePic.isNotEmpty)
                                      ? DecorationImage(
                                          image: NetworkImage(profilePic),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child:
                                    (profilePic == null || profilePic.isEmpty)
                                        ? Icon(Icons.people,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary)
                                        : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      seller['stallDescription'] ??
                                          'Açıklama yok',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.7),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: _AnimatedArrowIcon(
                                  color: Theme.of(context).colorScheme.primary,
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
        ),
      ],
    );
  }
}

class _AnimatedArrowIcon extends StatefulWidget {
  final Color color;
  const _AnimatedArrowIcon({required this.color});

  @override
  State<_AnimatedArrowIcon> createState() => _AnimatedArrowIconState();
}

class _AnimatedArrowIconState extends State<_AnimatedArrowIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<Offset>(begin: Offset.zero, end: const Offset(0.25, 0))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Icon(Icons.arrow_forward_ios, size: 14, color: widget.color),
    );
  }
}

class _MarketPickerSheet extends StatefulWidget {
  final List<Market> markets;
  final ScrollController scrollController;
  final Function(Market) onSelect;

  const _MarketPickerSheet(
      {required this.markets,
      required this.scrollController,
      required this.onSelect});

  @override
  State<_MarketPickerSheet> createState() => _MarketPickerSheetState();
}

class _MarketPickerSheetState extends State<_MarketPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String? _selectedCity;
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
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

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    // HomeViewModel'den yakındaki pazarları al (eğer varsa)
    final homeVM = Provider.of<HomeViewModel>(context, listen: false);
    final nearbyMarketIds = homeVM.nearbyMarkets.map((m) => m.id).toSet();

    final cities = widget.markets.map((m) => m.address.city).toSet().toList()
      ..sort();

    List<String> districts = [];
    if (_selectedCity != null) {
      districts = widget.markets
          .where((m) => m.address.city == _selectedCity)
          .map((m) => m.address.district)
          .toSet()
          .toList()
        ..sort();
    }

    final filtered = widget.markets.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_query.toLowerCase());
      final matchesCity =
          _selectedCity == null || m.address.city == _selectedCity;
      final matchesDistrict =
          _selectedDistrict == null || m.address.district == _selectedDistrict;
      return matchesSearch && matchesCity && matchesDistrict;
    }).toList();

    // Sıralama: Yakındakiler en üstte, sonra alfabetik
    filtered.sort((a, b) {
      final isANearby = nearbyMarketIds.contains(a.id);
      final isBNearby = nearbyMarketIds.contains(b.id);

      if (isANearby && !isBNearby) return -1;
      if (!isANearby && isBNearby) return 1;

      // İkisi de yakındaysa mesafeye göre sırala
      if (isANearby && isBNearby) {
        return a.distanceInMeters.compareTo(b.distanceInMeters);
      }

      return a.name.compareTo(b.name);
    });

    return Column(
      children: [
        if (cities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    context,
                    hint: langVM.translate('city'),
                    value: _selectedCity,
                    items: cities,
                    onChanged: (val) {
                      setState(() {
                        _selectedCity = val;
                        _selectedDistrict = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    context,
                    hint: 'İlçe',
                    value: _selectedDistrict,
                    items: districts,
                    onChanged: (val) {
                      setState(() {
                        _selectedDistrict = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomSearchBar(
            controller: _searchController,
            hintText: 'Pazar Ara...',
            onMicPressed: _listen,
            isListening: _isListening,
            onChanged: (val) => setState(() => _query = val),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: widget.scrollController,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final market = filtered[index];
              return ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(market.name, overflow: TextOverflow.ellipsis),
                    ),
                    if (nearbyMarketIds.contains(market.id))
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.near_me,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                  ],
                ),
                subtitle: Text(
                    '${market.address.district}, ${market.address.city} • ${(market.distanceInMeters / 1000).toStringAsFixed(1)} km'),
                onTap: () => widget.onSelect(market),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style:
                  TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Tümü',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
            ...items.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
