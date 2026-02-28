import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentation/widgets/svg_icon.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../viewmodels/language_viewmodel.dart';
import '../screens/Customer/login_screen.dart';
import 'Seller/seller_login_screen.dart';
import '../../../core/constants/app_icons.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  final VoidCallback? onLoginSuccess;

  const UserTypeSelectionScreen({super.key, this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/copilot_ikon.png',
                  height: 120,
                  width: 120,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                langVM.translate('home_title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                langVM.translate('select_user_type'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
              const Spacer(),
              _buildSelectionButton(
                context,
                title: langVM.translate('customer_label'),
                icon: const SvgIcon(
                    iconPath: AppIcons.user, size: 28, color: Colors.white),
                color: const Color.fromARGB(255, 27, 94, 32),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(
                        onLoginSuccess: onLoginSuccess ?? () {},
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSelectionButton(
                context,
                title: langVM.translate('seller_label'),
                icon:
                    const Icon(Icons.storefront, size: 28, color: Colors.white),
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SellerLoginScreen(),
                    ),
                  );
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionButton(BuildContext context,
      {required String title,
      required Widget icon,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
