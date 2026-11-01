import 'package:church_register/auth/models/app_user_role.dart';
import 'package:church_register/leaders/models/church_leader.dart';
import 'package:church_register/leaders/services/leader_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUserRole.hasAdminAccess', () {
    test('detecta admin y superadmin', () {
      expect(AppUserRole.hasAdminAccess([AppUserRole.admin]), isTrue);
      expect(AppUserRole.hasAdminAccess([AppUserRole.superAdmin]), isTrue);
      expect(
        AppUserRole.hasAdminAccess([AppUserRole.leader, AppUserRole.admin]),
        isTrue,
      );
    });

    test('no marca roles pastorales', () {
      expect(AppUserRole.hasAdminAccess([AppUserRole.leader]), isFalse);
      expect(
        AppUserRole.hasAdminAccess([
          AppUserRole.leader,
          AppUserRole.supervisor,
          AppUserRole.registrar,
        ]),
        isFalse,
      );
    });
  });

  group('LeaderService.leaderDocIndicatesAdmin', () {
    test('usa appRoles del documento leaders', () {
      final adminLeader = ChurchLeader(
        lastName: 'Admin',
        firstName: 'Ana',
        mobilePhone: '1',
        registeredAt: DateTime(2026),
        registeredBy: 'x@y.com',
        appRoles: [AppUserRole.admin],
      );
      final leader = ChurchLeader(
        lastName: 'Lopez',
        firstName: 'Miguel',
        mobilePhone: '1',
        registeredAt: DateTime(2026),
        registeredBy: 'x@y.com',
        appRoles: [AppUserRole.leader],
      );

      expect(LeaderService.leaderDocIndicatesAdmin(adminLeader), isTrue);
      expect(LeaderService.leaderDocIndicatesAdmin(leader), isFalse);
    });
  });
}
