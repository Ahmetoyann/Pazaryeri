import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/seller_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../Customer/edit_profile_screen.dart';

class SellerSettingsScreen extends StatefulWidget {
  const SellerSettingsScreen({super.key});

  @override
  State<SellerSettingsScreen> createState() => _SellerSettingsScreenState();
}

class _SellerSettingsScreenState extends State<SellerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    final sellerVM = Provider.of<SellerViewModel>(context, listen: false);
    _nameController = TextEditingController(text: sellerVM.stallName);
    _descController = TextEditingController(text: sellerVM.stallDescription);
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('saved_stall_name');
    final savedDesc = prefs.getString('saved_stall_desc');
    if (mounted) {
      if (savedName != null) _nameController.text = savedName;
      if (savedDesc != null) _descController.text = savedDesc;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null && mounted) {
      try {
        await Provider.of<AuthViewModel>(context, listen: false)
            .updateProfilePhoto(image.path);
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
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  langVM.translate('remove_photo'),
                  style: const TextStyle(color: Colors.red),
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
        Icon(icon, color: Colors.grey.shade600, size: 20),
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

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);
    final sellerVM = Provider.of<SellerViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final userImage = authVM.currentUser?.profilePicturePath;

    return Scaffold(
      appBar: AppBar(
        title: Text(langVM.translate('seller_settings_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: userImage != null
                          ? (userImage.startsWith('http')
                              ? NetworkImage(userImage)
                              : FileImage(File(userImage))) as ImageProvider
                          : null,
                      child: userImage == null
                          ? Icon(Icons.store,
                              size: 50, color: Colors.grey.shade400)
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
                    border: Border.all(color: Colors.grey.shade200),
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
                decoration: InputDecoration(
                  labelText: langVM.translate('stall_name_label'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.store),
                ),
                validator: (v) =>
                    v!.isEmpty ? langVM.translate('error_prefix') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: langVM.translate('stall_desc_label'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: sellerVM.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                              'saved_stall_name', _nameController.text);
                          await prefs.setString(
                              'saved_stall_desc', _descController.text);
                          await sellerVM.updateSellerProfile(
                            name: _nameController.text,
                            description: _descController.text,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(langVM
                                    .translate('success_settings_updated')),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: sellerVM.isLoading
                    ? const CircularProgressIndicator()
                    : Text(langVM.translate('save_changes')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
