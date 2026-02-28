import 'dart:ui';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentColor = Theme.of(context).colorScheme.primary;

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 21), // tavandan ayrık
        child: AppBar(
          title: title,
          actions: actions,
          leading: leading,
          centerTitle: centerTitle,
          automaticallyImplyLeading: automaticallyImplyLeading,
          backgroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: bottom,
          iconTheme: Theme.of(context).iconTheme.copyWith(
                color: contentColor,
              ),
          titleTextStyle: TextStyle(
            color: contentColor,
            fontWeight: FontWeight.w900,
            fontSize: 21,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.white.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(80 + (bottom?.preferredSize.height ?? 0));
}
