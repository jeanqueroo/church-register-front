import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ChurchLogo extends StatelessWidget {
  const ChurchLogo({super.key, this.size = 120});

  final double size;

  static const String assetPath = 'assets/images/logo_iglesia.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: appDisplayName,
      image: true,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.church,
          size: size * 0.6,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
