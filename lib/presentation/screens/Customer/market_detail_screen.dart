import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/market.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'product_detail_screen.dart';
import 'market_sellers_screen.dart';

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
  late double _currentOccupancy;
  bool _hasReportedPresence = false;
  XFile? _reviewImage;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _currentOccupancy = widget.market.occupancy;
    _loadReviews();
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

  Future<void> _pickReviewImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _reviewImage = image);
      }
    } catch (e) {
      debugPrint('Resim seçilemedi: $e');
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
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.near_me,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(widget.market.distanceInMeters / 1000).toStringAsFixed(1)} km',
                              style: const TextStyle(
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MarketSellersScreen(
                                marketId: widget.market.id,
                                marketName: widget.market.name),
                          ),
                        );
                      },
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
                      icon: const Icon(Icons.directions),
                      label: Text(langVM.translate('get_directions')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
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
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _pickReviewImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Fotoğraf Ekle'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
                if (_reviewImage != null) ...[
                  const SizedBox(width: 8),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_reviewImage!.path),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _reviewImage = null),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cancel,
                              color: Colors.red, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
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
                    'imagePath': _reviewImage?.path,
                  };

                  AuthService.instance
                      .addReview(review)
                      .then((_) => _loadReviews());

                  setState(() {
                    _userRating = 0;
                    _commentController.clear();
                    _reviewImage = null;
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
                if (review['imagePath'] != null &&
                    review['imagePath'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(
                              backgroundColor: Colors.black,
                              iconTheme:
                                  const IconThemeData(color: Colors.white),
                            ),
                            body: Center(
                              child: InteractiveViewer(
                                child: Image.file(
                                  File(review['imagePath']),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(review['imagePath']),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const SizedBox(),
                      ),
                    ),
                  ),
                ],
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

  void _showHourlyOccupancy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saatlik Yoğunluk Tahmini',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Veriler geçmiş ziyaretçi yoğunluğuna göre tahmin edilmiştir.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(13, (index) {
                    final hour = 8 + index; // 08:00 - 20:00
                    // Mock data generation
                    double density = 0.2;
                    if (hour >= 11 && hour <= 14) density = 0.8;
                    if (hour >= 16 && hour <= 18) density = 0.9;
                    if (hour == 10 || hour == 15) density = 0.5;

                    final random =
                        ((widget.market.id.hashCode + hour) % 30) / 100.0;
                    density = (density + random).clamp(0.1, 1.0);

                    final isCurrentHour = DateTime.now().hour == hour;

                    Color barColor;
                    if (density < 0.4) {
                      barColor = Colors.green;
                    } else if (density < 0.7) {
                      barColor = Colors.orange;
                    } else {
                      barColor = Colors.red;
                    }

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isCurrentHour)
                            Icon(Icons.arrow_drop_down,
                                size: 20,
                                color: Theme.of(context).primaryColor),
                          Container(
                            width: isCurrentHour ? 16 : 12,
                            height: 120 * density,
                            decoration: BoxDecoration(
                              color: barColor
                                  .withOpacity(isCurrentHour ? 1.0 : 0.5),
                              borderRadius: BorderRadius.circular(4),
                              border: isCurrentHour
                                  ? Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 2)
                                  : null,
                              boxShadow: isCurrentHour
                                  ? [
                                      BoxShadow(
                                        color: barColor.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$hour',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrentHour
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrentHour
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _reportPresence() {
    if (_hasReportedPresence) return;
    setState(() {
      _hasReportedPresence = true;
      _currentOccupancy = (_currentOccupancy + 0.05).clamp(0.0, 1.0);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bildiriminiz alındı, teşekkürler!')),
    );
  }

  Widget _buildOccupancyBar(BuildContext context) {
    // Market modelindeki occupancy değerini kullanıyoruz
    final occupancyRate = _currentOccupancy;
    final percent = (occupancyRate * 100).toInt();

    Color color;
    String label;
    IconData icon;
    String description;

    if (occupancyRate <= 0.4) {
      color = Colors.green;
      label = 'Tenha';
      icon = Icons.person_outline;
      description = 'Alışveriş için en uygun zaman.';
    } else if (occupancyRate <= 0.7) {
      color = Colors.orange;
      label = 'Normal';
      icon = Icons.people;
      description = 'Pazar yeri hareketli.';
    } else {
      color = Colors.red;
      label = 'Kalabalık';
      icon = Icons.groups;
      description = 'Pazar yeri oldukça yoğun.';
    }

    return GestureDetector(
      onTap: () => _showHourlyOccupancy(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anlık Doluluk Durumu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Icon(Icons.info_outline, size: 20, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dairesel Grafik
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    children: [
                      // Arka plan halkası
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          color: color.withOpacity(0.1),
                        ),
                      ),
                      // Doluluk halkası
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: occupancyRate,
                          strokeWidth: 12,
                          color: color,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Ortadaki Yüzde ve İkon
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: color, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              '%$percent',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Açıklama Metinleri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _hasReportedPresence ? null : _reportPresence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  disabledBackgroundColor: Colors.green,
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  _hasReportedPresence
                      ? Icons.check_circle
                      : Icons.person_pin_circle,
                ),
                label: Text(_hasReportedPresence
                    ? 'Bildiriminiz Alındı'
                    : 'Ben Buradayım (Yoğunluk Bildir)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
