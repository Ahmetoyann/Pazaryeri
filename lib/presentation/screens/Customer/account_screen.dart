// lib/presentation/screens/account_screen.dart

import 'dart:io';
import 'dart:ui';
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

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              _buildAnimatedItem(
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardColor,
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: userImage != null
                            ? (userImage.startsWith('http')
                                ? NetworkImage(userImage)
                                : FileImage(File(userImage))) as ImageProvider
                            : null,
                        child: userImage == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey.shade500,
                              )
                            : null,
                      ),
                    ),
                    if (authVM.isSeller)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.storefront,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                0,
              ),
              const SizedBox(height: 20),
              _buildAnimatedItem(
                SizedBox(
                  width: double.infinity,
                  child: _buildNormalButton(
                    context,
                    label: langVM.translate('edit_profile'),
                    icon: Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),
                1,
              ),
              const SizedBox(height: 20),
              // Favorilerim Butonu
              _buildAnimatedItem(
                _buildNormalCard(
                  context,
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.favorite, color: Colors.redAccent),
                    ),
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
                2,
              ),

              // Favori Satıcılar Butonu
              _buildAnimatedItem(
                _buildNormalCard(
                  context,
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store, color: Colors.orange),
                    ),
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
                3,
              ),

              // Yorumlarım Butonu
              _buildAnimatedItem(
                _buildNormalCard(
                  context,
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.comment, color: Colors.blueAccent),
                    ),
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
                4,
              ),
              // Dil Ayarları
              _buildAnimatedItem(
                _buildNormalCard(
                  context,
                  Consumer<LanguageViewModel>(
                    builder: (context, langVM, child) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.language, color: Colors.purple),
                        ),
                        title: Text(langVM.translate('language')),
                        trailing: DropdownButton<String>(
                          value: langVM.currentLanguage,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                                value: 'tr', child: Text('Türkçe')),
                            DropdownMenuItem(
                                value: 'en', child: Text('English')),
                          ],
                          onChanged: (val) {
                            if (val != null) langVM.changeLanguage(val);
                          },
                        ),
                      );
                    },
                  ),
                ),
                5,
              ),
              // Tema Ayarları
              _buildAnimatedItem(
                _buildNormalCard(
                  context,
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.palette, color: Colors.teal),
                    ),
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
                6,
              ),
              const SizedBox(height: 10),
              _buildAnimatedItem(
                Row(
                  children: [
                    Expanded(
                      child: _buildNormalButton(
                        context,
                        label: langVM.translate('logout'),
                        icon: Icons.logout,
                        color: Colors.orange.shade700,
                        onPressed: () async {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  langVM.translate('logout_confirmation_title'),
                                ),
                                content: Text(
                                  langVM
                                      .translate('logout_confirmation_message'),
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNormalButton(
                        context,
                        label: langVM.translate('delete_account'),
                        icon: Icons.delete_forever,
                        color: Colors.red,
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
                                      style: const TextStyle(color: Colors.red),
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
                      ),
                    ),
                  ],
                ),
                7,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalCard(BuildContext context, Widget child) {
    return _BouncingButton(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildNormalButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return _BouncingButton(
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final double begin = (index * 0.1).clamp(0.0, 1.0);
    final double end = (begin + 0.5).clamp(0.0, 1.0);

    final Animation<double> animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
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

class _BouncingButton extends StatefulWidget {
  final Widget child;
  const _BouncingButton({required this.child});

  @override
  State<_BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<_BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
