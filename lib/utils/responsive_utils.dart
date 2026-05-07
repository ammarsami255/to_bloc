import 'package:flutter/material.dart';

/// Responsive utilities for adapting UI to different screen sizes
class ResponsiveUtils {
  /// Check if the current device is a mobile (portrait phone)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if the current device is a tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if the current device is a desktop/web
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Get current device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Get responsive padding based on screen size
  static double getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 16;
    if (width < tabletBreakpoint) return 24;
    return 32;
  }

  /// Get responsive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 16;
    if (width < tabletBreakpoint) return 32;
    if (width < 1200) return 48;
    return 64;
  }

  /// Get responsive card aspect ratio
  static double getCardAspectRatio(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 3.2;
      case DeviceType.tablet:
        return 1.8;
      case DeviceType.desktop:
        return 2.2;
    }
  }

  /// Get responsive font size
  static double getFontSize(
    BuildContext context,
    double mobile,
    double tablet,
    double desktop,
  ) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  /// Get responsive cross-axis count for grid
  static int getGridCrossAxisCount(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
    }
  }

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1000;
}

enum DeviceType { mobile, tablet, desktop }

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, DeviceType) mobileBuilder;
  final Widget Function(BuildContext, DeviceType)? tabletBuilder;
  final Widget Function(BuildContext, DeviceType)? desktopBuilder;

  const ResponsiveBuilder({
    super.key,
    required this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileBuilder(context, deviceType);
      case DeviceType.tablet:
        return tabletBuilder?.call(context, deviceType) ??
            mobileBuilder(context, deviceType);
      case DeviceType.desktop:
        return desktopBuilder?.call(context, deviceType) ??
            tabletBuilder?.call(context, deviceType) ??
            mobileBuilder(context, deviceType);
    }
  }
}
