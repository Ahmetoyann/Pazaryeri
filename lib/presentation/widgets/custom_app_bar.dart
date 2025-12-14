import 'dart:ui';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 21), // tavandan ayrık
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4), // hafif yuvarlak köşeler
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5,
              sigmaY: 5,
            ), // daha az blur, daha şeffaf
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  0.1,
                ), // daha belirgin ve okunabilir arka plan
                borderRadius: BorderRadius.circular(4),
              ),
              child: AppBar(
                title: title,
                actions: actions,
                leading: leading,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                iconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.primary,
                ),
                titleTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
