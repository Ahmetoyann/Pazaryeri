import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import 'seller_edit_profile_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/custom_bottom_sheets.dart';
import '../../widgets/custom_snackbars.dart';
import '../../../core/constants/app_icons.dart';
import '../../../presentation/widgets/svg_icon.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_button.dart';

class SellerSettingsScreen extends StatefulWidget {
  const SellerSettingsScreen({super.key});

  @override
  State<SellerSettingsScreen> createState() => _SellerSettingsScreenState();
}

class _SellerSettingsScreenState extends State<SellerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _hoursController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;
  late TextEditingController _instagramNameController;
  late TextEditingController _facebookNameController;
  String _initialName = '';
  String _initialDesc = '';
  String _initialHours = '';
  String _initialInstagram = '';
  String _initialFacebook = '';
  String _initialInstagramName = '';
  String _initialFacebookName = '';
  bool _isChanged = false;

  @override
  void initState() {
    super.initState();
    final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
    _initialName = sellerVM.stallName ?? '';
    _initialDesc = sellerVM.stallDescription ?? '';
    // SellerViewModel'de henüz hours yoksa boş başlar, _loadSellerData ile güncellenir

    _nameController = TextEditingController(text: _initialName);
    _descController = TextEditingController(text: _initialDesc);
    _hoursController = TextEditingController(text: _initialHours);
    _instagramController = TextEditingController(text: _initialInstagram);
    _facebookController = TextEditingController(text: _initialFacebook);
    _instagramNameController =
        TextEditingController(text: _initialInstagramName);
    _facebookNameController = TextEditingController(text: _initialFacebookName);

    _nameController.addListener(_checkForChanges);
    _descController.addListener(_checkForChanges);
    _hoursController.addListener(_checkForChanges);
    _instagramController.addListener(_checkForChanges);
    _facebookController.addListener(_checkForChanges);
    _instagramNameController.addListener(_checkForChanges);
    _facebookNameController.addListener(_checkForChanges);

    _loadSellerData();
  }

  void _checkForChanges() {
    final hasChanges = _nameController.text != _initialName ||
        _descController.text != _initialDesc ||
        _hoursController.text != _initialHours ||
        _instagramController.text != _initialInstagram ||
        _facebookController.text != _initialFacebook ||
        _instagramNameController.text != _initialInstagramName ||
        _facebookNameController.text != _initialFacebookName;
    if (_isChanged != hasChanges) {
      setState(() => _isChanged = hasChanges);
    }
  }

  Future<void> _loadSellerData() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    if (authVM.currentUser != null) {
      // Firebase'den güncel verileri çek
      final data =
          await AuthService.instance.refreshUserData(authVM.currentUser!.id);
      if (data != null && mounted) {
        setState(() {
          if (data['stallName'] != null) {
            _initialName = data['stallName']!;
            _nameController.text = _initialName;
          }
          if (data['stallDescription'] != null) {
            _initialDesc = data['stallDescription']!;
            _descController.text = _initialDesc;
          }
          if (data['stallHours'] != null) {
            _initialHours = data['stallHours']!;
            _hoursController.text = _initialHours;
          }
          if (data['instagramLink'] != null) {
            _initialInstagram = data['instagramLink']!;
            _instagramController.text = _initialInstagram;
          }
          if (data['facebookLink'] != null) {
            _initialFacebook = data['facebookLink']!;
            _facebookController.text = _initialFacebook;
          }
          if (data['instagramName'] != null) {
            _initialInstagramName = data['instagramName']!;
            _instagramNameController.text = _initialInstagramName;
          }
          if (data['facebookName'] != null) {
            _initialFacebookName = data['facebookName']!;
            _facebookNameController.text = _initialFacebookName;
          }
          _isChanged = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _descController.removeListener(_checkForChanges);
    _hoursController.removeListener(_checkForChanges);
    _instagramController.removeListener(_checkForChanges);
    _facebookController.removeListener(_checkForChanges);
    _instagramNameController.removeListener(_checkForChanges);
    _facebookNameController.removeListener(_checkForChanges);
    _nameController.dispose();
    _descController.dispose();
    _hoursController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _instagramNameController.dispose();
    _facebookNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null && mounted) {
      final primaryColor = Theme.of(context).colorScheme.primary;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Profil Fotoğrafını Düzenle',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio:
                true, // Profil fotoğrafları için her zaman kare kalmasını sağlar
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: 'Profil Fotoğrafını Düzenle',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        try {
          await LoadingOverlay.show(
            context,
            asyncFunction: () async {
              await Provider.of<AuthViewModel>(context, listen: false)
                  .updateProfilePhoto(croppedFile.path);
            },
          );

          if (!mounted) return;
          final langVM = Provider.of<LanguageViewModel>(context, listen: false);
          await DialogService.showSuccess(
            context,
            message: langVM.translate('success_settings_updated'),
          );
        } catch (e) {
          if (mounted) {
            CustomSnackbars.showError(context, 'Fotoğraf güncellenemedi: $e');
          }
        }
      }
    }
  }

  void _showImagePicker(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    CustomBottomSheets.showImagePicker(
      context: context,
      cameraText: langVM.translate('camera'),
      galleryText: langVM.translate('gallery'),
      removeText: langVM.translate('remove_photo'),
      onCameraTap: () => _pickImage(ImageSource.camera),
      onGalleryTap: () => _pickImage(ImageSource.gallery),
      onRemoveTap: authVM.currentUser?.profilePicturePath != null
          ? () => authVM.removeProfilePhoto()
          : null,
    );
  }

  Widget _buildInfoRow(String iconPath, String text) {
    return Row(
      children: [
        SvgIcon(
            iconPath: iconPath,
            color: Theme.of(context).colorScheme.primary,
            size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    final bool? confirm = await CustomBottomSheets.showConfirmation(
      context: context,
      title: langVM.translate('logout_confirmation_title'),
      message: langVM.translate('logout_confirmation_message'),
      confirmText: langVM.translate('yes'),
      cancelText: langVM.translate('no'),
      icon: Icons.logout,
    );

    if (confirm == true && mounted) {
      await LoadingOverlay.show(context, asyncFunction: () async {
        authVM.logout();
        if (mounted) setState(() => _isChanged = false);
      });
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _selectStallHours() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final solidColor = isDark ? const Color(0xFF303030) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    // Açılış saati seçimi
    final TimeOfDay? openTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Açılış Saati',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: Theme.of(context).colorScheme.secondary,
                    onPrimary: Colors.white,
                    surface: solidColor,
                    onSurface: textColor,
                  )
                : ColorScheme.light(
                    primary: Theme.of(context).colorScheme.secondary,
                    onPrimary: Colors.white,
                    surface: solidColor,
                    onSurface: textColor,
                  ),
            dialogBackgroundColor: solidColor,
          ),
          child: child!,
        );
      },
    );

    if (openTime == null || !mounted) return;

    // Kapanış saati seçimi
    final TimeOfDay? closeTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      helpText: 'Kapanış Saati',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: Theme.of(context).colorScheme.secondary,
                    onPrimary: Colors.white,
                    surface: solidColor,
                    onSurface: textColor,
                  )
                : ColorScheme.light(
                    primary: Theme.of(context).colorScheme.secondary,
                    onPrimary: Colors.white,
                    surface: solidColor,
                    onSurface: textColor,
                  ),
            dialogBackgroundColor: solidColor,
          ),
          child: child!,
        );
      },
    );

    if (closeTime == null) return;

    final String formattedOpen =
        '${openTime.hour.toString().padLeft(2, '0')}:${openTime.minute.toString().padLeft(2, '0')}';
    final String formattedClose =
        '${closeTime.hour.toString().padLeft(2, '0')}:${closeTime.minute.toString().padLeft(2, '0')}';

    setState(() {
      _hoursController.text = '$formattedOpen - $formattedClose';
    });
  }

  InputDecoration _buildInputDecoration(String label, String? iconPath,
      {String? hintText}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: iconPath != null
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: SvgIcon(
                  iconPath: iconPath,
                  color: theme.colorScheme.primary,
                  size: 28))
          : null,
      filled: true,
      fillColor: isDark ? theme.cardColor : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final theme = Theme.of(context);
    final userImage = authVM.currentUser?.profilePicturePath;
    final bool hasImage = userImage != null && userImage.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isChanged,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final bool confirm = await DialogService.showConfirmation(
          context,
          title: 'Uyarı',
          message:
              'Değişiklikleri kaydetmediniz. Çıkmak istediğinize emin misiniz?',
          confirmText: langVM.translate('yes'),
          cancelText: langVM.translate('no'),
          icon: Icons.warning_amber_rounded,
          confirmColor: Colors.red,
        );

        if (confirm && mounted) {
          setState(() => _isChanged = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: Text(langVM.translate('seller_settings_title')),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profil Fotoğrafı Alanı
                Center(
                  child: GestureDetector(
                    onTap: () => _showImagePicker(context),
                    child: Stack(
                      children: [
                        if (!hasImage)
                          CustomPaint(
                            painter: _DashedBorderPainter(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                              borderRadius:
                                  60.0, // 120x120 kutuyu tam daire yapar
                            ),
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: theme.colorScheme.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    langVM.translate('add_photo_button'),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ClipOval(
                            child: userImage.startsWith('http')
                                ? Image.network(
                                    userImage,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(userImage),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        if (authVM.isUploadingProfilePhoto)
                          const Positioned.fill(
                            child: CustomLoadingIndicator(),
                          ),
                        if (hasImage)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primary,
                              child: SvgIcon(
                                  iconPath: AppIcons.camera,
                                  size: 22,
                                  color: theme.colorScheme.onPrimary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (authVM.currentUser != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? theme.cardColor : Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              langVM.translate('seller_details'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) =>
                                        const SellerEditProfileScreen()));
                              },
                              icon: SvgIcon(
                                  iconPath: AppIcons.edit,
                                  size: 22,
                                  color: theme.colorScheme.primary),
                              label: Text(langVM.translate('edit_profile')),
                              style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        _buildInfoRow(AppIcons.user,
                            '${authVM.currentUser!.firstName} ${authVM.currentUser!.lastName}'),
                        const Divider(height: 24),
                        _buildInfoRow(
                            AppIcons.email, authVM.currentUser!.email),
                        const Divider(height: 24),
                        _buildInfoRow(
                            AppIcons.phone, authVM.currentUser!.phoneNumber),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                      langVM.translate('stall_name_label'), AppIcons.market),
                  validator: (v) =>
                      v!.isEmpty ? langVM.translate('error_prefix') : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hoursController,
                  readOnly: true,
                  onTap: _selectStallHours,
                  decoration: _buildInputDecoration(
                      langVM.translate('stall_hours_label'), AppIcons.clock,
                      hintText: langVM.translate('stall_hours_hint')),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: _buildInputDecoration(
                      langVM.translate('stall_desc_label'), AppIcons.info),
                ),
                const SizedBox(height: 24),
                Text(
                  langVM.translate('social_media_title'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surface.withOpacity(0.3)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: theme.dividerColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgIcon(
                              iconPath: AppIcons.instagram,
                              size: 24,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(langVM.translate('instagram_label'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _instagramNameController,
                        decoration: _buildInputDecoration(
                            'Kullanıcı Adı (Örn: @pazar_esnafi)', null),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _instagramController,
                        decoration: _buildInputDecoration(
                            'Profil Linki (URL)', null,
                            hintText: 'https://instagram.com/...'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surface.withOpacity(0.3)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: theme.dividerColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgIcon(
                              iconPath: AppIcons.facebook,
                              size: 24,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(langVM.translate('facebook_label'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _facebookNameController,
                        decoration: _buildInputDecoration(
                            'Sayfa Adı (Örn: Pazar Esnafı)', null),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _facebookController,
                        decoration: _buildInputDecoration(
                            'Profil Linki (URL)', null,
                            hintText: 'https://facebook.com/...'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: langVM.translate('save_changes'),
                  isLoading: sellerVM.isLoading,
                  onPressed: (sellerVM.isLoading || !_isChanged)
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            await LoadingOverlay.show(
                              context,
                              asyncFunction: () async {
                                await sellerVM.updateSellerProfile(
                                  name: _nameController.text,
                                  description: _descController.text,
                                );

                                // Firebase'e kaydet
                                final authVM = Provider.of<AuthViewModel>(
                                    context,
                                    listen: false);
                                if (authVM.currentUser != null) {
                                  await AuthService.instance.updateUserInDb({
                                    'stallName': _nameController.text,
                                    'stallDescription': _descController.text,
                                    'stallHours': _hoursController.text,
                                    'instagramName':
                                        _instagramNameController.text,
                                    'instagramLink': _instagramController.text,
                                    'facebookName':
                                        _facebookNameController.text,
                                    'facebookLink': _facebookController.text,
                                  }, authVM.currentUser!.email);
                                }
                              },
                            );

                            if (mounted) {
                              setState(() {
                                _initialName = _nameController.text;
                                _initialDesc = _descController.text;
                                _initialHours = _hoursController.text;
                                _initialInstagramName =
                                    _instagramNameController.text;
                                _initialInstagram = _instagramController.text;
                                _initialFacebookName =
                                    _facebookNameController.text;
                                _initialFacebook = _facebookController.text;
                                _isChanged = false;
                              });

                              await DialogService.showSuccess(
                                context,
                                message: langVM
                                    .translate('success_settings_updated'),
                              );
                              if (mounted) Navigator.pop(context);
                            }
                          }
                        },
                ),
                const SizedBox(height: 32),
                // Pazarı Değiştir Butonu
                CustomButton(
                  text: langVM.translate('change_market'),
                  icon: Icons.swap_horiz,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  foregroundColor: theme.colorScheme.primary,
                  onPressed: () async {
                    final bool confirm = await DialogService.showConfirmation(
                      context,
                      title: langVM.translate('change_market_confirm_title'),
                      message:
                          langVM.translate('change_market_confirm_message'),
                      confirmText: langVM.translate('yes'),
                      cancelText: langVM.translate('no'),
                      icon: Icons.swap_horiz,
                      confirmColor: Colors.orange,
                    );

                    if (confirm && mounted) {
                      await LoadingOverlay.show(
                        context,
                        asyncFunction: () async {
                          setState(() => _isChanged = false);
                          final authVM = Provider.of<AuthViewModel>(context,
                              listen: false);

                          // Firestore'dan pazar bilgisini sil
                          if (authVM.currentUser != null) {
                            await AuthService.instance.updateUserInDb({
                              'sellerMarketId': '',
                            }, authVM.currentUser!.email);

                            // Ürünlerin pazar bilgisini de temizle
                            await AuthService.instance
                                .updateSellerProductsMarket(
                                    authVM.currentUser!.id, '');
                          }

                          // Mevcut pazar seçimini yerel hafızadan temizle
                          await AuthService.instance.updateSellerMarketId('');
                          authVM.setSellerMarketId('');
                        },
                      );

                      if (mounted) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Çıkış Yap Butonu
                CustomButton(
                  text: langVM.translate('logout'),
                  icon: Icons.logout,
                  onPressed: _showLogoutConfirmation,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
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
