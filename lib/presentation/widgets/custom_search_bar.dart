import 'package:flutter/material.dart';
import 'svg_icon.dart';
import '../../core/constants/app_icons.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onMicPressed;
  final bool isListening;
  final bool autoFocus;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onMicPressed,
    this.isListening = false,
    this.autoFocus = false,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autoFocus,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: theme.hintColor),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgIcon(
            iconPath: AppIcons.search,
            color: theme.hintColor,
          ),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: SvgIcon(
                  iconPath: AppIcons.close,
                  color: theme.hintColor,
                  size: 20,
                ),
                onPressed: () {
                  controller.clear();
                  if (onChanged != null) {
                    onChanged!('');
                  }
                },
              )
            : (onMicPressed != null
                ? IconButton(
                    icon: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      color: isListening ? Colors.redAccent : theme.hintColor,
                    ),
                    onPressed: onMicPressed,
                  )
                : null),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: isDark ? theme.cardColor : Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
