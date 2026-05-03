import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final double? elevation;
  final Color? contentColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.backgroundColor,
    this.elevation,
    this.contentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveContentColor =
        contentColor ?? Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && automaticallyImplyLeading) {
      final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
      if (parentRoute?.canPop ?? false) {
        effectiveLeading = IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        );
      }
    }

    if (effectiveLeading != null) {
      effectiveLeading = Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? surfaceColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: effectiveLeading,
        ),
      );
    }

    List<Widget>? effectiveActions;
    if (actions != null) {
      effectiveActions = actions!.map((action) {
        if (action is IconButton) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(minWidth: 40),
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isDark ? surfaceColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: action,
            ),
          );
        }
        return action;
      }).toList();
    }

    return AppBar(
      title: title,
      actions: effectiveActions,
      leading: effectiveLeading,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: elevation ?? 0,
      shadowColor: Colors.black.withOpacity(0.1),
      scrolledUnderElevation: elevation ?? 0,
      bottom: bottom,
      iconTheme: IconThemeData(
        color: isDark ? Colors.white.withOpacity(0.8) : effectiveContentColor,
      ),
      titleTextStyle: TextStyle(
        color: isDark ? Colors.white.withOpacity(0.8) : effectiveContentColor,
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
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
