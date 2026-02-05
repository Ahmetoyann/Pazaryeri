import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/auth_service.dart';
import '../Customer/edit_profile_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/success_dialog.dart';

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
  String _initialName = '';
  String _initialDesc = '';
  String _initialHours = '';
  String _initialInstagram = '';
  String _initialFacebook = '';
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

    _nameController.addListener(_checkForChanges);
    _descController.addListener(_checkForChanges);
    _hoursController.addListener(_checkForChanges);
    _instagramController.addListener(_checkForChanges);
    _facebookController.addListener(_checkForChanges);

    _loadSellerData();
  }

  void _checkForChanges() {
    final hasChanges = _nameController.text != _initialName ||
        _descController.text != _initialDesc ||
        _hoursController.text != _initialHours ||
        _instagramController.text != _initialInstagram ||
        _facebookController.text != _initialFacebook;
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
          _isChanged = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _hoursController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null && mounted) {
      try {
        await Provider.of<AuthViewModel>(context, listen: false)
            .updateProfilePhoto(image.path);
        if (mounted) {
          final langVM = Provider.of<LanguageViewModel>(context, listen: false);
          await DialogService.showSuccess(
            context,
            message: langVM.translate('success_settings_updated'),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  void _showImagePicker(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(langVM.translate('camera')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(langVM.translate('gallery')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (authVM.currentUser?.profilePicturePath != null)
              ListTile(
                leading: Icon(Icons.delete,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  langVM.translate('remove_photo'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  authVM.removeProfilePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);

    final bool confirm = await DialogService.showConfirmation(
      context,
      title: langVM.translate('logout_confirmation_title'),
      message: langVM.translate('logout_confirmation_message'),
      confirmText: langVM.translate('yes'),
      cancelText: langVM.translate('no'),
      icon: Icons.logout,
    );

    if (confirm == true && mounted) {
      setState(() => _isChanged = false);
      Provider.of<AuthViewModel>(context, listen: false).logout();
      Navigator.of(context).popUntil((route) => route.isFirst);
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

  InputDecoration _buildInputDecoration(String label, IconData icon,
      {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.5), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final userImage = authVM.currentUser?.profilePicturePath;

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
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          title: Text(langVM.translate('seller_settings_title')),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profil Fotoğrafı Alanı
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: userImage != null
                            ? (userImage.startsWith('http')
                                ? NetworkImage(userImage)
                                : FileImage(File(userImage))) as ImageProvider
                            : null,
                        child: userImage == null
                            ? Icon(Icons.store,
                                size: 50,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.4))
                            : null,
                      ),
                      if (authVM.isUploadingProfilePhoto)
                        const Positioned.fill(
                          child: CircularProgressIndicator(),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showImagePicker(context),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.camera_alt,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (authVM.currentUser != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              langVM.translate('seller_details'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen()));
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: Text(langVM.translate('edit_profile')),
                              style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        _buildInfoRow(Icons.person,
                            '${authVM.currentUser!.firstName} ${authVM.currentUser!.lastName}'),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.email, authVM.currentUser!.email),
                        const Divider(height: 24),
                        _buildInfoRow(
                            Icons.phone, authVM.currentUser!.phoneNumber),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                      langVM.translate('stall_name_label'), Icons.store),
                  validator: (v) =>
                      v!.isEmpty ? langVM.translate('error_prefix') : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hoursController,
                  readOnly: true,
                  onTap: _selectStallHours,
                  decoration: _buildInputDecoration(
                      langVM.translate('stall_hours_label'), Icons.access_time,
                      hintText: langVM.translate('stall_hours_hint')),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: _buildInputDecoration(
                      langVM.translate('stall_desc_label'), Icons.description),
                ),
                const SizedBox(height: 24),
                Text(
                  langVM.translate('social_media_title'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instagramController,
                  decoration: _buildInputDecoration(
                      langVM.translate('instagram_label'),
                      Icons.camera_alt_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _facebookController,
                  decoration: _buildInputDecoration(
                      langVM.translate('facebook_label'), Icons.facebook),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (sellerVM.isLoading || !_isChanged)
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            await sellerVM.updateSellerProfile(
                              name: _nameController.text,
                              description: _descController.text,
                            );

                            // Firebase'e kaydet
                            final authVM = Provider.of<AuthViewModel>(context,
                                listen: false);
                            if (authVM.currentUser != null) {
                              await AuthService.instance.updateUserInDb({
                                'stallName': _nameController.text,
                                'stallDescription': _descController.text,
                                'stallHours': _hoursController.text,
                                'instagramLink': _instagramController.text,
                                'facebookLink': _facebookController.text,
                              }, authVM.currentUser!.email);
                            }

                            if (mounted) {
                              setState(() {
                                _initialName = _nameController.text;
                                _initialDesc = _descController.text;
                                _initialHours = _hoursController.text;
                                _initialInstagram = _instagramController.text;
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
                  child: sellerVM.isLoading
                      ? const CircularProgressIndicator()
                      : Text(langVM.translate('save_changes')),
                ),
                const SizedBox(height: 32),
                // Pazarı Değiştir Butonu
                TextButton.icon(
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
                      setState(() => _isChanged = false);
                      final authVM =
                          Provider.of<AuthViewModel>(context, listen: false);
                      // Mevcut pazar seçimini yerel hafızadan temizle
                      await AuthService.instance.updateSellerMarketId('');
                      authVM.setSellerMarketId('');
                      if (mounted) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    }
                  },
                  icon: const Icon(Icons.swap_horiz, color: Colors.orange),
                  label: Text(
                    langVM.translate('change_market'),
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Çıkış Yap Butonu
                TextButton.icon(
                  onPressed: _showLogoutConfirmation,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    langVM.translate('logout'),
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
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
