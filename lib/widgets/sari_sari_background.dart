import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// A flexible data class to hold properties for any parallax item, be it an icon or text.
class ParallaxItem {
  final IconData? icon;
  final String? text;
  final double size;
  final double x; // X position as a factor of screen width (0.0 to 1.0)
  final double y; // Initial Y position
  final double rotation;
  final double speed; // Parallax speed factor

  const ParallaxItem({
    this.icon,
    this.text,
    required this.size,
    required this.x,
    required this.y,
    required this.rotation,
    required this.speed,
  }) : assert(icon != null || text != null, 'Either icon or text must be provided.');
}

class SariSariStoreBackground extends StatefulWidget {
  final Widget child;

  const SariSariStoreBackground({super.key, required this.child});

  @override
  State<SariSariStoreBackground> createState() => SariSariStoreBackgroundState();
}

class SariSariStoreBackgroundState extends State<SariSariStoreBackground> {
  double _scrollOffset = 0.0;

  // A hand-curated list of branded icons and text for the background layer (slower).
  final List<ParallaxItem> _backgroundItems = const [
    ParallaxItem(text: '₱', size: 55, x: 0.1, y: 120, rotation: -0.2, speed: 0.15),
    ParallaxItem(text: 'POS', size: 45, x: 0.85, y: 80, rotation: 0.15, speed: 0.1),
    ParallaxItem(icon: Icons.inventory_2_outlined, size: 60, x: 0.7, y: 250, rotation: 0.3, speed: 0.2),
    ParallaxItem(text: 'KIN', size: 50, x: 0.2, y: 400, rotation: 0.8, speed: 0.18),
    ParallaxItem(icon: Icons.local_mall_outlined, size: 55, x: 0.9, y: 550, rotation: -0.3, speed: 0.22),
    ParallaxItem(text: 'KIN', size: 60, x: 0.15, y: 700, rotation: 0.5, speed: 0.12),
    ParallaxItem(icon: Icons.local_drink_outlined, size: 50, x: 0.75, y: 820, rotation: 0.0, speed: 0.17),
    ParallaxItem(icon: Icons.storefront_outlined, size: 65, x: 0.45, y: 500, rotation: 0.1, speed: 0.16),
    ParallaxItem(icon: Icons.receipt_long_outlined, size: 50, x: 0.8, y: 950, rotation: -0.1, speed: 0.2),
  ];

  // A hand-curated list for the foreground layer (faster) for a dynamic effect.
  final List<ParallaxItem> _foregroundItems = const [
    ParallaxItem(text: 'JAZZ', size: 40, x: 0.3, y: 50, rotation: 0.1, speed: 0.4),
    ParallaxItem(text: '₱', size: 50, x: 0.8, y: 180, rotation: -0.4, speed: 0.5),
    ParallaxItem(icon: Icons.point_of_sale_outlined, size: 45, x: 0.05, y: 300, rotation: 0.3, speed: 0.45),
    ParallaxItem(icon: Icons.store_mall_directory_outlined, size: 40, x: 0.95, y: 420, rotation: 0.1, speed: 0.55),
    ParallaxItem(text: 'KIN', size: 38, x: 0.2, y: 600, rotation: -0.1, speed: 0.48),
    ParallaxItem(icon: Icons.rice_bowl_outlined, size: 55, x: 0.65, y: 750, rotation: 0.4, speed: 0.42),
    ParallaxItem(text: 'KIN', size: 40, x: 0.9, y: 950, rotation: -0.2, speed: 0.5),
    ParallaxItem(icon: Icons.payment_outlined, size: 45, x: 0.5, y: 480, rotation: -0.2, speed: 0.52),
    ParallaxItem(icon: Icons.calculate_outlined, size: 42, x: 0.75, y: 50, rotation: 0.25, speed: 0.6),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[850]! : const Color(0xFF1ABC9C);
    final backgroundItemColor = isDarkMode ? Colors.white.withAlpha(20) : Colors.white.withAlpha(51);
    final foregroundItemColor = isDarkMode ? Colors.white.withAlpha(38) : Colors.white.withAlpha(89);
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Container(color: backgroundColor),
        ..._buildItemLayer(_backgroundItems, backgroundItemColor, screenWidth),
        ..._buildItemLayer(_foregroundItems, foregroundItemColor, screenWidth),
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              setState(() {
                _scrollOffset = notification.metrics.pixels;
              });
            }
            return true;
          },
          child: widget.child,
        ),
      ],
    );
  }

  List<Widget> _buildItemLayer(List<ParallaxItem> items, Color color, double screenWidth) {
    return items.map((item) {
      Widget child;
      if (item.icon != null) {
        child = Icon(item.icon, size: item.size, color: color);
      } else {
        child = Text(
          item.text!,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: item.size,
            fontWeight: FontWeight.bold,
          ),
        );
      }

      return Positioned(
        top: item.y - (_scrollOffset * item.speed),
        left: item.x * screenWidth,
        child: Transform.rotate(
          angle: item.rotation * pi, // Use fractions of pi for rotation
          child: child,
        ),
      );
    }).toList();
  }
}
