import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/market.dart';
import '../viewmodels/language_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import 'auth_viewmodel.dart';
import 'auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../viewmodels/product_detail_screen.dart';

class MarketDetailScreen extends StatefulWidget {
  final Market market;
  final String? heroTag;

  const MarketDetailScreen({super.key, required this.market, this.heroTag});

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  double _userRating = 0;

  List<Map<String, dynamic>> _reviews = [];
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadReviews();
    _markers.add(
      Marker(
        markerId: MarkerId(widget.market.id),
        position: LatLng(
            widget.market.address.latitude, widget.market.address.longitude),
        infoWindow: InfoWindow(title: widget.market.name),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (mounted) setState(() {});
  }

  Future<void> _moveToUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        _mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    } catch (e) {
      debugPrint('Konuma gidilemedi: $e');
    }
  }

  Future<void> _loadReviews() async {
    final allReviews = await AuthService.instance.getReviews();
    final marketReviews =
        allReviews.where((r) => r['marketId'] == widget.market.id).toList();

    // Yorumları tarihe göre (yeniden eskiye) sırala
    marketReviews.sort(
      (a, b) => _parseDate(b['date']).compareTo(_parseDate(a['date'])),
    );

    setState(() {
      _reviews = marketReviews;
    });
  }

  DateTime _parseDate(String dateStr) {
    if (dateStr == 'Bugün') return DateTime.now();
    try {
      final parts = dateStr.split('.');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return DateTime(1970);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold(
      0.0,
      (sum, item) => sum + (item['rating'] as num),
    );
    return total / _reviews.length;
  }

  Future<void> _openMap() async {
    final lat = widget.market.address.latitude;
    final lng = widget.market.address.longitude;
    // Google Haritalar URL şeması
    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Harita açılamadı');
      }
    } catch (e) {
      debugPrint('Harita açılırken hata oluştu: $e');
    }
  }

  Future<void> _shareMarket() async {
    final lat = widget.market.address.latitude;
    final lng = widget.market.address.longitude;
    final mapUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final text =
        "${widget.market.name}\n${widget.market.address.neighborhood}, ${widget.market.address.district}\n$mapUrl";
    await Share.share(text);
  }

  void _setMapStyle(GoogleMapController controller) {
    // https://mapstyle.withgoogle.com/ adresinden alınan örnek koyu tema stili
    const String darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#263c3f"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6b9a76"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#38414e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#212a37"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca5b3"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1f2835"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3d19c"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2f3948"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#515c6d"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  }
]
    ''';

    if (Theme.of(context).brightness == Brightness.dark) {
      controller.setMapStyle(darkMapStyle);
    } else {
      controller.setMapStyle(null); // Varsayılan stil
    }
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final homeVM = Provider.of<HomeViewModel>(context);
    final authVM = context.watch<AuthViewModel>();
    final isFav = homeVM.isFavorite(widget.market.id);

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
    final isOpen = widget.market.openDays.contains(todayName);

    final baseTag = widget.heroTag ?? widget.market.id;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: Text(widget.market.name),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareMarket),
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            color: isFav ? Colors.red : Colors.white,
            onPressed: () {
              homeVM.toggleFavorite(widget.market.id);
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pazar Konumu (Statik Harita Görseli)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    widget.market.address.latitude,
                    widget.market.address.longitude,
                  ),
                  zoom: 15,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  _setMapStyle(controller);
                  _moveToUserLocation();
                },
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'market_icon_$baseTag',
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Hero(
                          tag: 'market_name_$baseTag',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.market.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isOpen ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOpen ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: isOpen ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOpen
                                  ? langVM.translate('market_open_status')
                                  : langVM.translate('market_closed_status'),
                              style: TextStyle(
                                color: isOpen ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildOccupancyBar(context),
                  const SizedBox(height: 24),
                  Text(
                    widget.market.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    context,
                    Icons.location_on,
                    langVM.translate('address_label'),
                    '${widget.market.address.neighborhood}, ${widget.market.address.district} / ${widget.market.address.city}',
                  ),
                  const SizedBox(height: 16),
                  _buildWeeklyCalendar(context),
                  const SizedBox(height: 24),
                  _buildProductsSection(context),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSellersBottomSheet(context),
                      icon: const Icon(Icons.people),
                      label: Text(langVM.translate('sellers_title')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openMap,
                      icon: const Icon(Icons.map),
                      label: Text(langVM.translate('get_directions')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    langVM.translate('reviews_title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildReviewForm(context),
                  const SizedBox(height: 24),
                  _buildReviewList(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSellersBottomSheet(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                langVM.translate('sellers_title'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: AuthService.instance
                      .fetchSellersForMarket(widget.market.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          langVM.translate('no_sellers_found'),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    final sellers = snapshot.data!;
                    return ListView.separated(
                      itemCount: sellers.length,
                      separatorBuilder: (ctx, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final seller = sellers[index];
                        final stallName = seller['stallName'] ??
                            '${seller['firstName']} ${seller['lastName']}';
                        final stallDesc = seller['stallDescription'] ?? '';
                        final profilePic = seller['profilePicture'];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (profilePic != null && profilePic.isNotEmpty)
                                    ? NetworkImage(profilePic)
                                    : null,
                            child: (profilePic == null || profilePic.isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            stallName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: stallDesc.isNotEmpty
                              ? Text(stallDesc,
                                  maxLines: 2, overflow: TextOverflow.ellipsis)
                              : null,
                          isThreeLine: stallDesc.isNotEmpty,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(context); // Satıcılar listesini kapat
                            _showSellerProducts(context, seller); // Ürünleri aç
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSellerProducts(BuildContext context, Map<String, dynamic> seller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${seller['stallName'] ?? seller['firstName']} Ürünleri',
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: AuthService.instance
                        .fetchSellerProductsFromDb(seller['id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Hata: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('Bu satıcının henüz ürünü yok.'));
                      }

                      final products = snapshot.data!;
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: products.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ListTile(
                            leading: _buildProductImage(product['imagePath']),
                            title: Text(product['name']),
                            subtitle: Text(
                                '${product['price']} ₺ / ${product['unit'] ?? 'Birim'}'),
                            trailing: product['inStock'] == true
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green, size: 16)
                                : const Icon(Icons.remove_circle,
                                    color: Colors.red, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    product: product,
                                    sellerName: seller['stallName'] ??
                                        '${seller['firstName']} ${seller['lastName']}',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProductImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.shopping_basket, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: path.startsWith('http')
          ? Image.network(
              path,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                color: Colors.grey[200],
                child: const Icon(Icons.error, color: Colors.grey),
              ),
            )
          : Image.file(
              File(path),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                color: Colors.grey[200],
                child: const Icon(Icons.error, color: Colors.grey),
              ),
            ),
    );
  }

  Widget _buildReviewForm(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              langVM.translate('rate_market'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _userRating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < _userRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  );
                },
              ).expand((widget) => [widget, const SizedBox(width: 4)]).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: langVM.translate('comment_hint'),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  if (_userRating == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(langVM.translate('please_rate'))),
                    );
                    return;
                  }
                  if (_commentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(langVM.translate('please_comment')),
                      ),
                    );
                    return;
                  }

                  final authVM = context.read<AuthViewModel>();
                  // Misafir kontrolü: Eğer misafirse uyarı göster ve giriş yapmaya yönlendir
                  if (authVM.isGuest) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(langVM.translate('guest_message')),
                        action: SnackBarAction(
                          label: langVM.translate('login'),
                          onPressed: () => authVM
                              .exitGuestMode(), // Giriş ekranına yönlendirir
                        ),
                      ),
                    );
                    return;
                  }

                  final user = authVM.currentUser;
                  final now = DateTime.now();
                  final dateStr =
                      '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

                  final review = {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'userId': user?.id,
                    'user': '${user?.firstName} ${user?.lastName}',
                    'rating': _userRating,
                    'comment': _commentController.text.trim(),
                    'date': dateStr,
                    'marketId': widget.market.id,
                    'marketName': widget.market.name,
                    'likes': [],
                  };

                  AuthService.instance
                      .addReview(review)
                      .then((_) => _loadReviews());

                  setState(() {
                    _userRating = 0;
                    _commentController.clear();
                  });
                  FocusScope.of(context).unfocus();
                },
                child: Text(langVM.translate('send_button')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList(BuildContext context) {
    final authVM = context.read<AuthViewModel>();

    return Column(
      children: _reviews.map((review) {
        // Kullanıcı ismine göre renk seçimi (Her isim için sabit bir renk üretir)
        final colorIndex =
            review['user'].hashCode.abs() % Colors.primaries.length;
        final color = Colors.primaries[colorIndex];

        final isCurrentUser = review['userId'] != null &&
            review['userId'] == authVM.currentUser?.id;
        final profilePic =
            isCurrentUser ? authVM.currentUser?.profilePicturePath : null;

        final likes = (review['likes'] as List<dynamic>?) ?? [];
        final isLiked = authVM.currentUser != null &&
            likes.contains(authVM.currentUser!.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              profilePic != null ? Colors.transparent : color,
                          backgroundImage: profilePic != null
                              ? (profilePic.startsWith('http')
                                      ? NetworkImage(profilePic)
                                      : FileImage(File(profilePic)))
                                  as ImageProvider
                              : null,
                          child: profilePic == null
                              ? Text(
                                  review['user'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review['user'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          review['date'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        if (isCurrentUser)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                _confirmDeleteReview(context, review['id']),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review['rating'] ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(review['comment']),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () async {
                        if (authVM.currentUser == null) return;
                        if (review['id'] == null) return;

                        await AuthService.instance.toggleReviewLike(
                          review['id'],
                          authVM.currentUser!.id,
                        );
                        _loadReviews();
                      },
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            size: 18,
                            color: isLiked
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${likes.length}',
                            style: TextStyle(
                              color: isLiked
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _confirmDeleteReview(
    BuildContext context,
    String reviewId,
  ) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langVM.translate('delete_review_title')),
        content: Text(langVM.translate('delete_review_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(langVM.translate('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              langVM.translate('yes'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.deleteReview(reviewId);
      _loadReviews();
    }
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendar(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    final days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    final shortDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final todayIndex = DateTime.now().weekday - 1;

    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              langVM.translate('open_days_label'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final dayName = days[index];
            final isOpen = widget.market.openDays.contains(dayName);
            final isToday = index == todayIndex;

            return Column(
              children: [
                Text(
                  shortDays[index],
                  style: TextStyle(
                    color: isToday
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: isToday
                        ? Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      isOpen ? Icons.check : Icons.circle,
                      size: isOpen ? 20 : 8,
                      color: isOpen ? Colors.white : Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final products = widget.market.products;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shopping_basket,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              langVM.translate('products_label'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              langVM.translate('general_products'),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_offer,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        product,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildOccupancyBar(BuildContext context) {
    // Simülasyon: ID'ye göre sabit bir doluluk oranı üret (0.0 - 1.0 arası)
    final occupancyRate = (widget.market.id.hashCode % 101) / 100.0;
    final percent = (occupancyRate * 100).toInt();

    Color color;
    String label;
    if (occupancyRate < 0.4) {
      color = Colors.green;
      label = 'Tenha';
    } else if (occupancyRate < 0.7) {
      color = Colors.orange;
      label = 'Normal';
    } else {
      color = Colors.red;
      label = 'Kalabalık';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Anlık Doluluk',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                fontSize: 16,
              ),
            ),
            Text(
              '$label (%$percent)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: occupancyRate,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 12,
          ),
        ),
      ],
    );
  }
}
