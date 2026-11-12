import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen background combining teal, turquoise, and white across every view.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.appBackgroundGradient),
      child: child,
    );
  }
}

/// Renders the custom My Health Tracker app icon asset inside UI headers.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    this.size = 48,
    this.borderRadius = 12,
    this.withWhiteFrame = false,
  });

  final double size;
  final double borderRadius;
  final bool withWhiteFrame;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/images/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (!withWhiteFrame) {
      return image;
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(borderRadius + 2),
        border: Border.all(color: AppColors.turquoiseLight, width: 1),
      ),
      child: image,
    );
  }
}

/// Shared bottom-sheet container with a white-to-turquoise gradient background.
class AppSheetContainer extends StatelessWidget {
  const AppSheetContainer({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.sheetGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.turquoiseBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tealDark,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.tealDark),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

