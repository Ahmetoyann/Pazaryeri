// lib/presentation/screens/account_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'register_screen.dart'; // register_screen.dart dosyasını import edin
import 'package:provider/provider.dart';

import 'auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'my_reviews_screen.dart';
import 'theme_settings_screen.dart';
import '../widgets/custom_app_bar.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ViewModel'deki değişiklikleri dinlemek için 'watch' kullanıyoruz.
    final authVM = context.watch<AuthViewModel>();
    final langVM = context.watch<LanguageViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: Text(langVM.translate('account_title')),
        // Kullanıcı giriş yapmışsa AppBar'da da çıkış butonu gösterebiliriz
        actions: [
          if (authVM.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Çıkış Yap',
              onPressed: () async {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        langVM.translate('logout_confirmation_title'),
                      ),
                      content: Text(
                        langVM.translate('logout_confirmation_message'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(langVM.translate('no')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(langVM.translate('yes')),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true && context.mounted) {
                  context.read<AuthViewModel>().logout();
                }
              },
            ),
        ],
      ),
      // Kullanıcının durumuna göre (giriş yapmış veya misafir)
      // farklı bir gövde (body) gösteriyoruz.
      body: authVM.isAuthenticated
          ? Padding(
              padding: const EdgeInsets.only(top: 100),
              child: _buildLoggedInView(context, authVM),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 100),
              child: _buildGuestView(context),
            ),
    );
  }

  /// Kullanıcı giriş yapmışsa gösterilecek olan widget.
  Widget _buildLoggedInView(BuildContext context, AuthViewModel authVM) {
    final langVM = context.watch<LanguageViewModel>();
    final userImage = authVM.currentUser?.profilePicturePath;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) {
                    final lang = context.read<LanguageViewModel>();
                    return SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_camera),
                            title: Text(lang.translate('camera')),
                            onTap: () async {
                              Navigator.of(ctx).pop();
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.camera,
                              );
                              if (image != null && context.mounted) {
                                final croppedFile = await _cropImage(
                                  image,
                                  context,
                                );
                                if (croppedFile != null && context.mounted) {
                                  context
                                      .read<AuthViewModel>()
                                      .updateProfilePhoto(croppedFile.path);
                                }
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: Text(lang.translate('gallery')),
                            onTap: () async {
                              Navigator.of(ctx).pop();
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (image != null && context.mounted) {
                                final croppedFile = await _cropImage(
                                  image,
                                  context,
                                );
                                if (croppedFile != null && context.mounted) {
                                  context
                                      .read<AuthViewModel>()
                                      .updateProfilePhoto(croppedFile.path);
                                }
                              }
                            },
                          ),
                          if (authVM.currentUser?.profilePicturePath != null)
                            ListTile(
                              leading: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              title: Text(
                                lang.translate('remove_photo'),
                                style: const TextStyle(color: Colors.red),
                              ),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                context
                                    .read<AuthViewModel>()
                                    .removeProfilePhoto();
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: userImage != null
                    ? (userImage.startsWith('http')
                              ? NetworkImage(userImage)
                              : FileImage(File(userImage)))
                          as ImageProvider
                    : null,
                child: userImage == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            // HATA GİDERİLDİ: 'user' yerine 'currentUser' kullanılıyor.
            // Kullanıcıya ismiyle hitap etmek daha iyi bir deneyim sunar.
            Text(
              '${context.read<LanguageViewModel>().translate('welcome')}, ${authVM.currentUser?.firstName ?? ''}!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              authVM.currentUser?.email ?? '',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                context.read<LanguageViewModel>().translate('edit_profile'),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Favorilerim Butonu
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.redAccent),
              title: Text(
                context.read<LanguageViewModel>().translate('favorites_title'),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
              },
            ),

            // Yorumlarım Butonu
            ListTile(
              leading: const Icon(Icons.comment, color: Colors.blueAccent),
              title: Text(
                context.read<LanguageViewModel>().translate('my_reviews'),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
                );
              },
            ),
            // Dil Ayarları
            Consumer<LanguageViewModel>(
              builder: (context, langVM, child) {
                return ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(langVM.translate('language')),
                  trailing: DropdownButton<String>(
                    value: langVM.currentLanguage,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (val) {
                      if (val != null) langVM.changeLanguage(val);
                    },
                  ),
                );
              },
            ),
            // Tema Ayarları
            ListTile(
              leading: const Icon(Icons.palette),
              title: Text(
                langVM.translate('theme_settings'),
              ), //langVM hata veriyor
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ThemeSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: Text(
                context.read<LanguageViewModel>().translate('logout'),
              ),
              onPressed: () async {
                final langVM = context.read<LanguageViewModel>();
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        langVM.translate('logout_confirmation_title'),
                      ),
                      content: Text(
                        langVM.translate('logout_confirmation_message'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(langVM.translate('no')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(langVM.translate('yes')),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true && context.mounted) {
                  context.read<AuthViewModel>().logout();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.grey),
              label: Text(
                context.read<LanguageViewModel>().translate('delete_account'),
                style: const TextStyle(color: Colors.grey),
              ),
              onPressed: () async {
                final langVM = context.read<LanguageViewModel>();
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        langVM.translate('delete_account_confirm_title'),
                      ),
                      content: Text(
                        langVM.translate('delete_account_confirm_message'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(langVM.translate('no')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            langVM.translate('yes'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true && context.mounted) {
                  context.read<AuthViewModel>().deleteAccount();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<CroppedFile?> _cropImage(XFile imageFile, BuildContext context) async {
    return await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Fotoğrafı Kırp',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Fotoğrafı Kırp'),
      ],
    );
  }

  /// Misafir kullanıcı veya giriş yapmamış kullanıcı için gösterilecek olan widget.
  Widget _buildGuestView(BuildContext context) {
    final langVM = context.watch<LanguageViewModel>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 80,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              langVM.translate('guest_message'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Giriş Yap Butonu
            ElevatedButton(
              onPressed: () {
                // Misafir modundan çıkış yapıyoruz.
                // AuthWrapper durumu algılayıp otomatik olarak LoginScreen'e yönlendirecektir.
                context.read<AuthViewModel>().logout();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.white),
              ),
              child: Text(
                langVM.translate('login'),
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            // Kayıt Ol Butonu
            OutlinedButton(
              onPressed: () {
                // Login ekranına değil, doğrudan Register ekranına yönlendirir.
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(langVM.translate('create_account')),
                  SizedBox(width: 8),
                  Icon(
                    Icons.add_box,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
