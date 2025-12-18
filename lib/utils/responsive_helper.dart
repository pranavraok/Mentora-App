import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double _baseWidth = 375.0;
  static const double _baseHeight = 812.0;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double fontSize(BuildContext context, double size) {
    final width = screenWidth(context);
    double scaledSize = (size / _baseWidth) * width;

    // Clamp font size between 70% and 130% of original for consistency
    return scaledSize.clamp(size * 0.7, size * 1.3);
  }

  static double spacing(BuildContext context, double size) {
    final width = screenWidth(context);
    return (size / _baseWidth) * width;
  }

  static double height(BuildContext context, double size) {
    final height = screenHeight(context);
    return (size / _baseHeight) * height;
  }

  static double scale(BuildContext context) => screenWidth(context) / _baseWidth;

  static bool isSmallScreen(BuildContext context) => screenWidth(context) < 360;
  static bool isTablet(BuildContext context) => screenWidth(context) >= 600;
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool autoScale; // NEW: Option to disable auto-scaling if needed

  const ResponsiveText(
      this.text, {
        super.key,
        this.style,
        this.textAlign,
        this.maxLines = 1, // DEFAULT to 1 line
        this.overflow = TextOverflow.ellipsis, // DEFAULT to ellipsis
        this.autoScale = true, // DEFAULT to auto-scale
      });

  @override
  Widget build(BuildContext context) {
    if (autoScale) {
      // Use FittedBox for auto-scaling - keeps text on one line
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft, // CRITICAL: Prevents shifting
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: 1, // Force single line when auto-scaling
          softWrap: false, // Prevent wrapping
        ),
      );
    } else {
      // Use standard Text with proper overflow handling
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: maxLines != null && maxLines! > 1,
      );
    }
  }
}
