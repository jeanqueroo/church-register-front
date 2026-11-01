import 'package:flutter/material.dart';

import '../../church/services/church_service.dart';
import 'church_display_name.dart';

class ChurchLogo extends StatelessWidget {
  const ChurchLogo({
    super.key,
    this.size = 120,
    this.churchId,
    this.churchService,
  });

  final double size;
  final String? churchId;
  final ChurchService? churchService;

  static const String assetPath = 'assets/images/logo_iglesia.png';

  @override
  Widget build(BuildContext context) {
    final service = churchService ?? ChurchService();

    return StreamBuilder(
      stream: service.watchChurch(churchId),
      builder: (context, snapshot) {
        final logoUrl = snapshot.data?.logoUrl;
        final hasNetworkLogo =
            logoUrl != null && logoUrl.trim().isNotEmpty;

        return Semantics(
          label: resolveChurchDisplayName(snapshot.data),
          image: true,
          child: hasNetworkLogo
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    logoUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _assetLogo(context),
                  ),
                )
              : _assetLogo(context),
        );
      },
    );
  }

  Widget _assetLogo(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.church,
        size: size * 0.6,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
