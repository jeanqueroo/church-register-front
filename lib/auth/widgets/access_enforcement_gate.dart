import 'package:flutter/material.dart';

import '../../church/services/church_service.dart';
import '../models/access_block.dart';
import '../models/user_profile.dart';
import '../screens/blocked_account_screen.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

/// Impide el acceso si el usuario o su iglesia asignada están bloqueados.
class AccessEnforcementGate extends StatelessWidget {
  const AccessEnforcementGate({
    super.key,
    required this.session,
    required this.authService,
    required this.userProfileService,
    required this.churchService,
    required this.child,
  });

  final UserSession session;
  final AuthService authService;
  final UserProfileService userProfileService;
  final ChurchService churchService;
  final Widget child;

  AccessBlock? _blockFromProfile(UserProfile profile) {
    if (profile.permissions.isSuperAdmin) return null;
    if (profile.isBlocked) return const AccessBlock(AccessBlockKind.user);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: userProfileService.watchProfile(session.uid),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data ?? session.profile;
        final userBlock = _blockFromProfile(profile);

        if (userBlock != null) {
          return BlockedAccountScreen(
            authService: authService,
            block: userBlock,
          );
        }

        final churchId = profile.churchId;
        final isChurchAdmin = profile.permissions.isAdmin &&
            churchId != null &&
            churchId.isNotEmpty;

        if (!isChurchAdmin) {
          return child;
        }

        return StreamBuilder(
          stream: churchService.watchChurch(churchId),
          builder: (context, churchSnapshot) {
            if (churchSnapshot.connectionState == ConnectionState.waiting &&
                !churchSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final church = churchSnapshot.data;
            if (church != null && church.isBlocked) {
              return BlockedAccountScreen(
                authService: authService,
                block: const AccessBlock(AccessBlockKind.church),
              );
            }

            return child;
          },
        );
      },
    );
  }
}
