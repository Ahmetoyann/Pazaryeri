import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/market.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'product_detail_screen.dart';
import 'market_sellers_screen.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class MarketDetailScreen extends StatefulWidget {
  final Market market;
  final String? heroTag;
  final String? highlightReviewId;

  const MarketDetailScreen({
    super.key,
    required this.market,
    this.heroTag,
    this.highlightReviewId,
  });

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
  String? _marketImagePath;

  List<Map<String, dynamic>> _reviews = [];
  final Map<String, GlobalKey> _reviewKeys = {};
  String _sortOption = 'newest';
  final GlobalKey _reviewsTitleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentOccupancy = _calculateDynamicOccupancy(widget.market.id);
    _loadReviews();
    _loadMarketImage();
  }

  // Saate göre dinamik doluluk oranı hesapla (MarketCard ile aynı mantık)
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

  Future<void> _loadReviews() async {
    final marketReviews =
        await AuthService.instance.getMarketReviews(widget.market.id);
    if (mounted) {
      setState(() {
        _reviews = marketReviews;
        _sortReviews();
      });

      if (widget.highlightReviewId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _scrollToHighlightedItem(widget.highlightReviewId!);
          });
        });
      }
    }
  }

  void _sortReviews() {
    if (_sortOption == 'newest') {
      _reviews.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
    } else if (_sortOption == 'oldest') {
      _reviews.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
        return dateA.compareTo(dateB);
      });
    } else if (_sortOption == 'rating_high') {
      _reviews.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return ratingB.compareTo(ratingA);
      });
    } else if (_sortOption == 'rating_low') {
      _reviews.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return ratingA.compareTo(ratingB);
      });
    }
  }

  void _scrollToHighlightedItem(String id) {
    final key = _reviewKeys[id];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
    }
  }

  Future<void> _loadMarketImage() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('markets')
          .doc(widget.market.id)
          .get();
      if (doc.exists && doc.data() != null && doc.data()!['imageUrl'] != null) {
        if (mounted) {
          setState(() {
            _marketImagePath = doc.data()!['imageUrl'];
          });
        }
      }
    } catch (e) {
      debugPrint('Pazar görseli yüklenemedi: $e');
    }
  }

  Future<void> _pickMarketImage(ImageSource source) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Görseli Düzenle',
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ],
            ),
            IOSUiSettings(
              title: 'Görseli Düzenle',
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ],
            ),
          ],
        );

        if (croppedFile != null) {
          await LoadingOverlay.show(
            context,
            asyncFunction: () async {
              // Cloudinary'ye Yükleme
              const cloudName = 'doe2nzhgx';
              const uploadPreset = 'Pazaryeri';

              final uri = Uri.parse(
                  'https://api.cloudinary.com/v1_1/$cloudName/image/upload');
              final request = http.MultipartRequest('POST', uri)
                ..fields['upload_preset'] = uploadPreset
                ..files.add(await http.MultipartFile.fromPath(
                    'file', croppedFile.path));

              final response = await request.send();
              if (response.statusCode == 200) {
                final responseData = await response.stream.bytesToString();
                final jsonResponse = json.decode(responseData);
                final String imageUrl = jsonResponse['secure_url'];

                // Firestore'a kaydet (Herkes görebilsin diye)
                await FirebaseFirestore.instance
                    .collection('markets')
                    .doc(widget.market.id)
                    .set({
                  'imageUrl': imageUrl,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                setState(() {
                  _marketImagePath = imageUrl;
                });
              } else {
                throw Exception('Görsel Cloudinary\'ye yüklenemedi');
              }
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Pazar görseli seçilemedi/yüklenemedi: $e');
      if (mounted) {
        CustomSnackbars.showError(
            context, 'Görsel yüklenirken bir hata oluştu.');
      }
    }
  }

  Future<void> _pickReviewImage(ImageSource source) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (image != null) {
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Görseli Düzenle',
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ],
            ),
            IOSUiSettings(
              title: 'Görseli Düzenle',
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ],
            ),
          ],
        );
        if (croppedFile != null) {
          setState(() => _reviewImage = XFile(croppedFile.path));
        }
      }
    } catch (e) {
      debugPrint('Resim seçilemedi: $e');
    }
  }

  void _showImageSourceActionSheet() {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    CustomBottomSheets.showImagePicker(
      context: context,
      cameraText: langVM.translate('camera'),
      galleryText: langVM.translate('gallery'),
      onCameraTap: () => _pickReviewImage(ImageSource.camera),
      onGalleryTap: () => _pickReviewImage(ImageSource.gallery),
    );
  }

  void _showMarketImageActionSheet() {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    CustomBottomSheets.showImagePicker(
      context: context,
      cameraText: langVM.translate('camera'),
      galleryText: langVM.translate('gallery'),
      onCameraTap: () => _pickMarketImage(ImageSource.camera),
      onGalleryTap: () => _pickMarketImage(ImageSource.gallery),
    );
  }

  void _showFullScreenImage() {
    if (_marketImagePath == null) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.9),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: InteractiveViewer(
                child: Hero(
                  tag: 'market_image_${widget.market.id}',
                  child: _marketImagePath!.startsWith('http')
                      ? Image.network(_marketImagePath!, fit: BoxFit.contain)
                      : Image.file(File(_marketImagePath!),
                          fit: BoxFit.contain),
                ),
              ),
            ),
          );
        },
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
    final isOpenDay = widget.market.openDays.contains(todayName);

    // Saat kontrolü
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = 5 * 60; // 05:00
    final isBeforeOpening = isOpenDay && currentMinutes < startMinutes;
    final isOpenNow = isOpenDay && currentMinutes >= startMinutes;

    final baseTag = widget.heroTag ?? widget.market.id;

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(widget.market.name),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            color: isFav ? Colors.red : null,
            onPressed: () async {
              if (await authVM.checkGuestStatus(context)) {
                homeVM.toggleFavorite(widget.market.id);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_marketImagePath != null) ...[
                    GestureDetector(
                      onTap: _showFullScreenImage,
                      child: Stack(
                        children: [
                          Hero(
                            tag: 'market_image_${widget.market.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _marketImagePath!.startsWith('http')
                                  ? Image.network(
                                      _marketImagePath!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_marketImagePath!),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: _showMarketImageActionSheet,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                child: Icon(
                                  Icons.add_a_photo_outlined,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    GestureDetector(
                      onTap: _showMarketImageActionSheet,
                      child: CustomPaint(
                        painter: _DashedBorderPainter(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                          borderRadius: 16.0,
                        ),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_a_photo_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Pazar görseli ekle',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                              Icons.storefront,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32,
                            )),
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
                          color: isBeforeOpening
                              ? Colors.orange.withOpacity(0.1)
                              : (isOpenNow
                                  ? Colors.green.withOpacity(0.1)
                                  : Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withOpacity(0.1)),
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
                                    : (isOpenNow
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.error),
                                shape: BoxShape.circle,
                              ),
                              child: SvgIcon(
                                iconPath: isOpenNow
                                    ? AppIcons.check
                                    : (isBeforeOpening
                                        ? AppIcons.clock
                                        : AppIcons.close),
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isBeforeOpening
                                  ? "05.00'te kurulacak"
                                  : (isOpenNow
                                      ? langVM.translate('market_open_status')
                                      : langVM
                                          .translate('market_closed_status')),
                              style: TextStyle(
                                color: isBeforeOpening
                                    ? Colors.orange
                                    : (isOpenNow
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.error),
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
                            color: Colors.white.withOpacity(0.3),
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
                            SvgIcon(
                              iconPath: AppIcons.nearMe,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
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
                  _buildDetailRow(
                    context,
                    AppIcons.location,
                    langVM.translate('address_label'),
                    '${widget.market.description}\n${widget.market.address.neighborhood}, ${widget.market.address.district} / ${widget.market.address.city}',
                    trailing: IconButton(
                      icon: const Icon(Icons.ios_share_rounded, size: 22),
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: 'Pazarı Paylaş',
                      onPressed: _shareMarket,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        SvgIcon(
                            iconPath: AppIcons.clock,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              langVM.translate('average_working_hours'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              langVM.translate('working_hours_value'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildWeeklyCalendar(context),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _openMap,
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.directions,
                                          color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        langVM.translate('get_directions'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    key: _reviewsTitleKey,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            langVM.translate('reviews_title'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.2),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortOption,
                            icon: Icon(Icons.sort,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _sortOption = newValue;
                                  _sortReviews();
                                });
                              }
                            },
                            items: [
                              DropdownMenuItem(
                                value: 'newest',
                                child: Text(langVM.translate('sort_newest')),
                              ),
                              DropdownMenuItem(
                                value: 'oldest',
                                child: Text(langVM.translate('sort_oldest')),
                              ),
                              DropdownMenuItem(
                                value: 'rating_high',
                                child:
                                    Text(langVM.translate('sort_rating_high')),
                              ),
                              DropdownMenuItem(
                                value: 'rating_low',
                                child:
                                    Text(langVM.translate('sort_rating_low')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildReviewForm(context),
                  const SizedBox(height: 24),
                  _buildReviewList(context),
                  const SizedBox(height: 40),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                langVM.translate('rate_market'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_reviews.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SvgIcon(
                            iconPath: AppIcons.star,
                            color: Colors.amber,
                            size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _userRating = (index + 1).toDouble();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: AnimatedScale(
                        scale: _userRating >= index + 1 ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _userRating >= index + 1
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 36,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            maxLines: 4,
            minLines: 3,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              alignLabelWithHint: true,
              labelText: langVM.translate('comment_hint'),
              labelStyle:
                  TextStyle(color: Theme.of(context).colorScheme.primary),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.05),
              prefixIcon: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 12, right: 8, top: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.rate_review_rounded,
                        color: Theme.of(context).colorScheme.primary, size: 20),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _showImageSourceActionSheet,
                icon: SvgIcon(
                    iconPath: AppIcons.camera,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary),
                label: const Text('Fotoğraf Ekle'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
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
                        child: const SvgIcon(
                            iconPath: AppIcons.close,
                            color: Colors.red,
                            size: 20),
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
            child: CustomButton(
              text: langVM.translate('send_button'),
              icon: Icons.send_rounded,
              isFullWidth: false,
              onPressed: () async {
                if (_userRating == 0) {
                  CustomSnackbars.showWarning(
                      context, langVM.translate('please_rate'));
                  return;
                }
                if (_commentController.text.trim().isEmpty) {
                  CustomSnackbars.showWarning(
                      context, langVM.translate('please_comment'));
                  return;
                }

                final authVM = context.read<AuthViewModel>();
                if (!await authVM.checkGuestStatus(context)) {
                  return;
                }

                final user = authVM.currentUser;

                // Fotoğraf varsa yükle
                String? imageUrl;
                if (_reviewImage != null) {
                  imageUrl = await AuthService.instance
                      .uploadReviewImage(File(_reviewImage!.path));
                }

                final review = {
                  'userId': user?.id,
                  'user': '${user?.firstName} ${user?.lastName}',
                  'userProfilePicture': user?.profilePicturePath,
                  'rating': _userRating,
                  'comment': _commentController.text.trim(),
                  'date': DateTime.now().toIso8601String(),
                  'marketId': widget.market.id,
                  'marketName': widget.market.name,
                  'likes': [],
                  'imageUrl': imageUrl,
                };

                await AuthService.instance.addMarketReview(review);
                _loadReviews();

                setState(() {
                  _userRating = 0;
                  _commentController.clear();
                  _reviewImage = null;
                });
                FocusScope.of(context).unfocus();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    final displayedReviews = _reviews.take(5).toList();
    final langVM = Provider.of<LanguageViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        ...displayedReviews.map((review) {
          // Kullanıcı ismine göre renk seçimi (Her isim için sabit bir renk üretir)
          final colorIndex =
              review['user'].hashCode.abs() % Colors.primaries.length;
          final color = Colors.primaries[colorIndex];

          final isCurrentUser = review['userId'] != null &&
              review['userId'] == authVM.currentUser?.id;
          final profilePic = isCurrentUser
              ? authVM.currentUser?.profilePicturePath
              : review['userProfilePicture'];

          final likes = (review['likes'] as List<dynamic>?) ?? [];
          final isLiked = authVM.currentUser != null &&
              likes.contains(authVM.currentUser!.id);

          final isHighlighted = widget.highlightReviewId == review['id'];
          if (!_reviewKeys.containsKey(review['id'])) {
            _reviewKeys[review['id']] = GlobalKey();
          }

          return Container(
            key: _reviewKeys[review['id']],
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                  : (isDark ? Theme.of(context).cardColor : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: isHighlighted
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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
                          review['date'] != null
                              ? DateTime.parse(review['date'])
                                  .toString()
                                  .split(' ')[0]
                              : '',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        if (isCurrentUser)
                          IconButton(
                            icon: const SvgIcon(
                              iconPath: AppIcons.delete,
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
                if (review['imageUrl'] != null &&
                    review['imageUrl'].toString().isNotEmpty) ...[
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
                                child: Image.network(
                                  review['imageUrl'],
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
                      child: Image.network(
                        review['imageUrl'],
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
          );
        }),
        if (_reviews.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _AllMarketReviewsScreen(
                        marketId: widget.market.id,
                        marketName: widget.market.name,
                      ),
                    ),
                  );
                },
                child: Text(langVM.translate('see_all_reviews')),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDeleteReview(
    BuildContext context,
    String reviewId,
  ) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final confirm = await CustomBottomSheets.showConfirmation(
      context: context,
      title: langVM.translate('delete_review_title'),
      message: langVM.translate('delete_review_confirm'),
      confirmText: langVM.translate('yes'),
      cancelText: langVM.translate('no'),
      iconPath: AppIcons.delete,
    );

    if (confirm == true) {
      await AuthService.instance.deleteMarketReview(reviewId);
      _loadReviews();
    }
  }

  Widget _buildDetailRow(
    BuildContext context,
    String iconPath,
    String title,
    String value, {
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgIcon(
            iconPath: iconPath,
            color: Theme.of(context).colorScheme.primary,
            size: 28),
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
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
            SvgIcon(
              iconPath: AppIcons.calendar,
              color: Theme.of(context).colorScheme.primary,
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
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    border: isToday
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: isOpen
                        ? const SvgIcon(
                            iconPath: AppIcons.check,
                            size: 20,
                            color: Colors.white,
                          )
                        : SvgIcon(
                            iconPath: AppIcons.close,
                            size: 8,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.2),
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

  void _showHourlyOccupancy(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    CustomBottomSheets.showContent(
      context: context,
      title: langVM.translate('hourly_occupancy_title'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            langVM.translate('hourly_occupancy_desc'),
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
                final hour = 8 + index; // 08:00 - 20:00 (13 saat)

                // Dinamik yoğunluk hesaplama (Her saat için)
                // Pazar ID'sine ve saate göre tutarlı rastgelelik
                final random = Random(
                    widget.market.id.hashCode + DateTime.now().day + hour);
                final baseRandom = random.nextDouble() * 0.2;

                double baseOccupancy = 0.1;
                if (hour >= 8 && hour < 11)
                  baseOccupancy = 0.3; // Sabah
                else if (hour >= 11 && hour < 14)
                  baseOccupancy = 0.7; // Öğle
                else if (hour >= 14 && hour < 17)
                  baseOccupancy = 0.5; // Öğleden sonra
                else if (hour >= 17 && hour < 20)
                  baseOccupancy = 0.8; // Akşam
                else if (hour >= 20) baseOccupancy = 0.2; // Kapanış

                double density = (baseOccupancy + baseRandom).clamp(0.1, 1.0);

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
                            size: 20, color: Theme.of(context).primaryColor),
                      Container(
                        width: isCurrentHour ? 16 : 12,
                        height: 120 * density,
                        decoration: BoxDecoration(
                          color:
                              barColor.withOpacity(isCurrentHour ? 1.0 : 0.5),
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
  }

  void _reportPresence() {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    if (_hasReportedPresence) return;
    setState(() {
      _hasReportedPresence = true;
      _currentOccupancy = (_currentOccupancy + 0.05).clamp(0.0, 1.0);
    });
    CustomSnackbars.showSuccess(
        context, langVM.translate('presence_reported_success'));
  }

  Widget _buildOccupancyBar(BuildContext context) {
    // Market modelindeki occupancy değerini kullanıyoruz
    final occupancyRate = _currentOccupancy;
    final langVM = Provider.of<LanguageViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color color;
    String label;
    IconData icon;
    String description;

    if (occupancyRate <= 0.4) {
      color = Theme.of(context).colorScheme.primary;
      label = langVM.translate('occupancy_low');
      icon = Icons
          .person_outline; // Yoğunluk ikonları için SVG yoksa Icon kalabilir
      description = langVM.translate('occupancy_low_desc');
    } else if (occupancyRate <= 0.7) {
      color = Theme.of(context).colorScheme.secondary;
      label = langVM.translate('occupancy_medium');
      icon = Icons.people;
      description = langVM.translate('occupancy_medium_desc');
    } else {
      color = Theme.of(context).colorScheme.error;
      label = langVM.translate('occupancy_high');
      icon = Icons.groups;
      description = langVM.translate('occupancy_high_desc');
    }

    return GestureDetector(
      onTap: () => _showHourlyOccupancy(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                SvgIcon(
                    iconPath: AppIcons.chart,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    langVM.translate('current_occupancy_title'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                SvgIcon(
                    iconPath: AppIcons.info,
                    size: 20,
                    color: Colors.grey.shade400),
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
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: occupancyRate),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Stack(
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
                              value: value,
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
                                  '%${(value * 100).toInt()}',
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
                      );
                    },
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
            CustomButton(
              text: _hasReportedPresence
                  ? langVM.translate('presence_reported_button')
                  : langVM.translate('report_presence_button'),
              icon: _hasReportedPresence
                  ? Icons.check_circle
                  : Icons.person_pin_circle,
              onPressed: _hasReportedPresence ? null : _reportPresence,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashWidth = 8.0,
    this.dashSpace = 6.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();
    final dashedPath = Path();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class _AllMarketReviewsScreen extends StatefulWidget {
  final String marketId;
  final String marketName;

  const _AllMarketReviewsScreen({
    required this.marketId,
    required this.marketName,
  });

  @override
  State<_AllMarketReviewsScreen> createState() =>
      _AllMarketReviewsScreenState();
}

class _AllMarketReviewsScreenState extends State<_AllMarketReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews =
        await AuthService.instance.getMarketReviews(widget.marketId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeleteReview(String reviewId) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final confirm = await CustomBottomSheets.showConfirmation(
      context: context,
      title: langVM.translate('delete_review_title'),
      message: langVM.translate('delete_review_confirm'),
      confirmText: langVM.translate('yes'),
      cancelText: langVM.translate('no'),
      iconPath: AppIcons.delete,
    );

    if (confirm == true) {
      await AuthService.instance.deleteMarketReview(reviewId);
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar:
          CustomAppBar(title: Text('${widget.marketName} Değerlendirmeleri')),
      body: _isLoading
          ? const Center(child: CustomLoadingIndicator())
          : _reviews.isEmpty
              ? const Center(child: Text('Henüz değerlendirme yok.'))
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                      16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    final colorIndex =
                        review['user'].hashCode.abs() % Colors.primaries.length;
                    final color = Colors.primaries[colorIndex];

                    final isCurrentUser = review['userId'] != null &&
                        review['userId'] == authVM.currentUser?.id;
                    final profilePic = isCurrentUser
                        ? authVM.currentUser?.profilePicturePath
                        : review['userProfilePicture'];

                    final likes = (review['likes'] as List<dynamic>?) ?? [];
                    final isLiked = authVM.currentUser != null &&
                        likes.contains(authVM.currentUser!.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
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
                                      backgroundColor: profilePic != null
                                          ? Colors.transparent
                                          : color,
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
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      review['date'] != null
                                          ? DateTime.parse(review['date'])
                                              .toString()
                                              .split(' ')[0]
                                          : '',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isCurrentUser)
                                      IconButton(
                                        icon: const SvgIcon(
                                          iconPath: AppIcons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () =>
                                            _confirmDeleteReview(review['id']),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < review['rating']
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(review['comment']),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
