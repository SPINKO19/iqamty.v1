import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';

class CustomMenuButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;

  const CustomMenuButton({
    super.key,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.menu_rounded, color: iconColor ?? Colors.white),
        onPressed: () {
          // Use our global NavProvider to open the root sidebar
          context.read<NavProvider>().openDrawer();
        },
      ),
    );
  }
}
