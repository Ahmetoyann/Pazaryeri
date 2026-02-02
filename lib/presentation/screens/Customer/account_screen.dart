// lib/presentation/screens/account_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import '../Seller/favorite_sellers_screen.dart';
import 'my_reviews_screen.dart';
import 'theme_settings_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/success_dialog.dart';

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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 120.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: userImage != null
                    ? (userImage.startsWith('http')
                        ? NetworkImage(userImage)
                        : FileImage(File(userImage))) as ImageProvider
                    : null,
                child: userImage == null
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey,
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
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
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.redAccent),
                  title: Text(
                    context
                        .read<LanguageViewModel>()
                        .translate('favorites_title'),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const FavoritesScreen()),
                    );
                  },
                ),
              ),

              // Favori Satıcılar Butonu
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.store, color: Colors.orange),
                  title: Text(
                    context
                        .read<LanguageViewModel>()
                        .translate('favorite_sellers_title'),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const FavoriteSellersScreen()),
                    );
                  },
                ),
              ),

              // Yorumlarım Butonu
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.comment, color: Colors.blueAccent),
                  title: Text(
                    context.read<LanguageViewModel>().translate('my_reviews'),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MyReviewsScreen()),
                    );
                  },
                ),
              ),
              // Dil Ayarları
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Consumer<LanguageViewModel>(
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
              ),
              // Tema Ayarları
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
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
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout, size: 20),
                          label: Text(
                            langVM.translate('logout'),
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () async {
                            final bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                    langVM
                                        .translate('logout_confirmation_title'),
                                  ),
                                  content: Text(
                                    langVM.translate(
                                        'logout_confirmation_message'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(langVM.translate('no')),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
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
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever, size: 20),
                          label: Text(
                            langVM.translate('delete_account'),
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () async {
                            final bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                    langVM.translate(
                                        'delete_account_confirm_title'),
                                  ),
                                  content: Text(
                                    langVM.translate(
                                        'delete_account_confirm_message'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(langVM.translate('no')),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(
                                        langVM.translate('yes'),
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true && context.mounted) {
                              try {
                                await context
                                    .read<AuthViewModel>()
                                    .deleteAccount();
                                if (context.mounted) {
                                  await showFarewellDialog(context);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  await showErrorDialog(context,
                                      message: 'Hata: $e');
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

            // Google ile Bağla Butonu
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await context.read<AuthViewModel>().loginWithGoogle();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.g_mobiledata, size: 32),
              label: Text(langVM.translate('connect_with_google')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
