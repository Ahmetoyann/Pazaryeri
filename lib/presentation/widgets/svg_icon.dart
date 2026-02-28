import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String iconPath;
  final double? size;
  final Color? color;

  const SvgIcon({
    super.key,
    required this.iconPath,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Eğer renk belirtilmemişse, IconTheme'den (tema renginden) al
    final iconColor = color ?? IconTheme.of(context).color;

    return SvgPicture.asset(
      iconPath,
      width: size,
      height: size,
      colorFilter: iconColor != null
          ? ColorFilter.mode(iconColor, BlendMode.srcIn)
          : null,
    );
  }
}
