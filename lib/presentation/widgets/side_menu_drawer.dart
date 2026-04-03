import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/language_viewmodel.dart';
import '../viewmodels/auth_service.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../screens/Customer/edit_profile_screen.dart';
import '../screens/Customer/favorites_screen.dart';
import '../screens/Customer/my_questions_screen.dart';
import '../screens/Customer/my_reviews_screen.dart';
import '../screens/Customer/theme_settings_screen.dart';
import '../screens/Customer/notifications_screen.dart';
import '../screens/Customer/login_screen.dart';
import 'custom_bottom_sheets.dart';
import 'custom_snackbars.dart';
import '../../core/constants/app_icons.dart';
import '../../presentation/widgets/svg_icon.dart';
import 'loading_overlay.dart';
import 'custom_app_bar.dart';
import 'custom_button.dart';

class SideMenuDrawer extends StatelessWidget {
  const SideMenuDrawer({super.key});

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final authVM = context.read<AuthViewModel>();

    final bool? confirm = await CustomBottomSheets.showConfirmation(
      context: context,
      title: langVM.translate('logout_confirmation_title'),
      message: langVM.translate('logout_confirmation_message'),
      confirmText: langVM.translate('logout'),
      cancelText: langVM.translate('cancel'),
      icon: Icons.logout,
      confirmColor: Theme.of(context).colorScheme.error,
    );

    if (confirm == true) {
      await LoadingOverlay.show(context, asyncFunction: () async {
        authVM.logout();
      });

      // Çıkış yapıldıktan sonra drawer'ı kapat
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Hero(
                    tag: 'drawer_profile_photo',
                    child: imagePath.startsWith('http')
                        ? Image.network(imagePath)
                        : Image.file(File(imagePath)),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendEmail(
      BuildContext context, String subject, String body) async {
    final String email = 'ahmedoyan101@gmail.com';
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    try {
      // Android 11+ üzerinde canLaunchUrl, manifest ayarı yoksa false dönebilir.
      // Bu yüzden doğrudan launchUrl deniyoruz.
      if (!await launchUrl(emailLaunchUri,
          mode: LaunchMode.externalApplication)) {
        throw Exception('Uygulama başlatılamadı');
      }
    } catch (e) {
      if (context.mounted) {
        // Hata durumunda e-postayı panoya kopyala ve kullanıcıyı bilgilendir
        final langVM = Provider.of<LanguageViewModel>(context, listen: false);
        await Clipboard.setData(ClipboardData(text: email));
        CustomSnackbars.showError(
            context, '${langVM.translate('email_app_not_found')} $email');
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _showContactForm(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context, listen: false);
    final messageController = TextEditingController();
    final stt.SpeechToText speech = stt.SpeechToText();
    bool isListening = false;
    String originalText = '';
    String? selectedSubject;
    final List<String> subjectKeys = [
      'subject_suggestion',
      'subject_complaint',
      'subject_bug',
      'subject_support',
      'subject_other',
    ];

    CustomBottomSheets.showContent(
      context: context,
      title: langVM.translate('contact_form_title'),
      child: StatefulBuilder(
        builder: (context, setState) {
          void toggleListening() async {
            if (!isListening) {
              bool available = await speech.initialize(
                onStatus: (val) {
                  if (val == 'done' || val == 'notListening') {
                    try {
                      setState(() => isListening = false);
                    } catch (e) {
                      // ignore: state might be disposed
                    }
                  }
                },
                onError: (val) => setState(() => isListening = false),
              );
              if (available) {
                setState(() {
                  isListening = true;
                  originalText = messageController.text;
                });
                speech.listen(
                  onResult: (val) {
                    setState(() {
                      final newText = val.recognizedWords;
                      messageController.text = originalText.isEmpty
                          ? newText
                          : '$originalText $newText';
                    });
                  },
                );
              }
            } else {
              setState(() => isListening = false);
              speech.stop();
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedSubject,
                dropdownColor: Colors.black,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: langVM.translate('subject_label'),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  prefixIcon: Icon(Icons.subject,
                      color: Theme.of(context).colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5),
                  ),
                ),
                items: subjectKeys.map((String key) {
                  return DropdownMenuItem<String>(
                    value: langVM.translate(key),
                    child: Text(langVM.translate(key),
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSubject = newValue;
                  });
                },
                hint: Text(
                  langVM.translate('select_hint'),
                  style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.5)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: langVM.translate('message_label'),
                  hintText: langVM.translate('message_hint'),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                    color: isListening
                        ? Colors.red
                        : Theme.of(context).iconTheme.color,
                    onPressed: toggleListening,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: langVM.translate('send_button'),
                icon: Icons.send,
                onPressed: () {
                  if (selectedSubject == null ||
                      messageController.text.isEmpty) {
                    CustomSnackbars.showWarning(
                        context, langVM.translate('fill_all_fields'));
                    return;
                  }
                  Navigator.pop(context); // Formu kapat
                  _sendEmail(context, selectedSubject!, messageController.text);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToAbout(BuildContext context, LanguageViewModel langVM) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            title: Text(langVM.translate('help_support_title')),
          ),
          body: Container(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/images/copilot_ikon.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.info, size: 80)),
                ),
                const SizedBox(height: 32),
                Text(
                  'Pazaryeri',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    langVM.translate('app_slogan'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: langVM.translate('contact_us_title'),
                      icon: Icons.support_agent,
                      onPressed: () {
                        CustomBottomSheets.showContent(
                          context: context,
                          title: langVM.translate('contact_us_title'),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                langVM.translate('contact_us_desc'),
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                text: langVM.translate('create_form_button'),
                                onPressed: () {
                                  Navigator.pop(context); // İlk sheet'i kapat
                                  _showContactForm(context); // Formu aç
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateWithLoading(BuildContext context, Widget page) async {
    await LoadingOverlay.show(context, asyncFunction: () async {});
    if (context.mounted) {
      Navigator.pop(context); // Drawer'ı kapat
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final langVM = context.watch<LanguageViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final theme = Theme.of(context);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.80,
      backgroundColor: theme.brightness == Brightness.dark
          ? Colors.black
          : theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Üst Başlık (Kullanıcı Bilgileri)
          _buildHeader(context, authVM, langVM),

          // Menü Listesi
          Expanded(
            child: authVM.isAuthenticated
                ? _buildLoggedInMenu(context, langVM, authVM, themeVM)
                : _buildGuestMenu(context, langVM, authVM, themeVM),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, AuthViewModel authVM, LanguageViewModel langVM) {
    final user = authVM.currentUser;
    final userImage = user?.profilePicturePath;
    final theme = Theme.of(context);

    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(32),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(32),
            ),
            child: Stack(
              children: [
                // Arka plan deseni
                Positioned(
                  right: -30,
                  bottom: -20,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Image.asset(
                      'assets/images/copilot_ikon.png',
                      width: 180,
                      height: 180,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                // İçerik
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 24,
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  child: authVM.isAuthenticated
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (userImage != null) {
                                          _showFullScreenImage(
                                              context, userImage);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Hero(
                                          tag: 'drawer_profile_photo',
                                          child: CircleAvatar(
                                            radius: 32,
                                            backgroundColor: theme.cardColor,
                                            backgroundImage:
                                                userImage != null
                                                    ? (userImage.startsWith(
                                                                'http')
                                                            ? NetworkImage(
                                                                userImage)
                                                            : FileImage(File(
                                                                userImage)))
                                                        as ImageProvider
                                                    : null,
                                            child: userImage == null
                                                ? SvgIcon(
                                                    iconPath: AppIcons.profile,
                                                    size: 32,
                                                    color: Colors.grey.shade400)
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -12),
                                  child: IconButton(
                                    onPressed: () =>
                                        _showLogoutConfirmation(context),
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const SvgIcon(
                                        iconPath: AppIcons.logout,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${user?.firstName} ${user?.lastName}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: const Icon(Icons.person_off,
                                  size: 32, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              langVM.translate('guest_user_title'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              langVM.translate('guest_user_subtitle'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoggedInMenu(BuildContext context, LanguageViewModel langVM,
      AuthViewModel authVM, ThemeViewModel themeVM) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildMenuSection(
          context,
          langVM.translate('account_section'),
          [
            _buildMenuItem(
              context,
              iconPath: AppIcons.profile,
              title: langVM.translate('edit_profile'),
              onTap: () =>
                  _navigateWithLoading(context, const EditProfileScreen()),
              trailing:
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              autoClose: false,
            ),
            _buildMenuItem(
              context,
              iconPath: AppIcons.notification,
              title: langVM.translate('notifications_title'),
              onTap: () =>
                  _navigateWithLoading(context, const NotificationsScreen()),
              autoClose: false,
              trailing: authVM.currentUser != null
                  ? StreamBuilder<List<Map<String, dynamic>>>(
                      stream: AuthService.instance
                          .getUserNotifications(authVM.currentUser!.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final unreadCount = snapshot.data!
                              .where((n) => n['read'] == false)
                              .length;
                          if (unreadCount > 0) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount > 9
                                        ? '9+'
                                        : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right,
                                    size: 20, color: Colors.grey),
                              ],
                            );
                          }
                        }
                        return const Icon(Icons.chevron_right,
                            size: 20, color: Colors.grey);
                      },
                    )
                  : const Icon(Icons.chevron_right,
                      size: 20, color: Colors.grey),
            ),
            _buildMenuItem(
              context,
              iconData: Icons.favorite_border,
              title: langVM.translate('favorites_title'),
              onTap: () =>
                  _navigateWithLoading(context, const FavoritesScreen()),
              trailing:
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              autoClose: false,
            ),
            _buildMenuItem(
              context,
              iconPath: AppIcons.question,
              title: langVM.translate('my_questions_title'),
              onTap: () =>
                  _navigateWithLoading(context, const MyQuestionsScreen()),
              trailing:
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              autoClose: false,
            ),
            _buildMenuItem(
              context,
              iconPath: AppIcons.starBorder,
              title: langVM.translate('my_ratings_title'),
              onTap: () =>
                  _navigateWithLoading(context, const MyReviewsScreen()),
              trailing:
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              autoClose: false,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildMenuSection(
          context,
          langVM.translate('general_section'),
          [
            _buildMenuItem(
              context,
              iconPath: AppIcons.settings,
              title: langVM.translate('theme_settings'),
              onTap: () =>
                  _navigateWithLoading(context, const ThemeSettingsScreen()),
              autoClose: false,
              trailing:
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ),
            _buildLanguageItem(context, langVM),
            _buildMenuItem(
              context,
              iconPath: AppIcons.help,
              title: langVM.translate('help_support_title'),
              onTap: () async {
                await LoadingOverlay.show(context, asyncFunction: () async {});
                if (context.mounted) {
                  Navigator.pop(context);
                  _navigateToAbout(context, langVM);
                }
              },
              autoClose: false,
              trailing:
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ),
          ],
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildGuestMenu(BuildContext context, LanguageViewModel langVM,
      AuthViewModel authVM, ThemeViewModel themeVM) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildMenuSection(
          context,
          langVM.translate('login_section'),
          [
            Padding(
              padding: const EdgeInsets.all(12),
              child: CustomButton(
                text: langVM.translate('login'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(
                        onLoginSuccess: () {},
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildMenuSection(
          context,
          langVM.translate('general_section'),
          [
            _buildMenuItem(
              context,
              iconPath: AppIcons.settings,
              title: langVM.translate('theme_settings'),
              onTap: () =>
                  _navigateWithLoading(context, const ThemeSettingsScreen()),
              autoClose: false,
              trailing:
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ),
            _buildLanguageItem(context, langVM),
            _buildMenuItem(
              context,
              iconPath: AppIcons.help,
              title: langVM.translate('help_support_title'),
              onTap: () async {
                await LoadingOverlay.show(context, asyncFunction: () async {});
                if (context.mounted) {
                  Navigator.pop(context);
                  _navigateToAbout(context, langVM);
                }
              },
              autoClose: false,
              trailing:
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ),
          ],
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildMenuSection(
      BuildContext context, String title, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    String? iconPath,
    IconData? iconData,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    Widget? trailing,
    bool autoClose = true,
  }) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: iconPath != null
            ? SvgIcon(iconPath: iconPath, color: color, size: 20)
            : Icon(iconData, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: () {
        if (autoClose) Navigator.pop(context); // Drawer'ı kapat
        onTap();
      },
    );
  }

  Widget _buildLanguageItem(BuildContext context, LanguageViewModel langVM) {
    final color = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.language, color: color, size: 20),
      ),
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
  }

  Widget _buildFooter() {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Opacity(
            opacity: 0.5,
            child: Image.asset(
              'assets/images/copilot_ikon.png',
              width: 60,
              height: 60,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Pazaryeri v1.0.0',
              style:
                  TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
