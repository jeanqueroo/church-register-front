import 'package:church_register/auth/models/app_permissions.dart';
import 'package:church_register/auth/models/app_user_role.dart';
import 'package:church_register/core/models/leader_gender.dart';
import 'package:church_register/leaders/models/church_leader.dart';
import 'package:church_register/leaders/services/leader_service.dart';
import 'package:church_register/l10n/app_localizations.dart';
import 'package:church_register/members/models/church_member.dart';
import 'package:church_register/members/models/marital_status.dart';
import 'package:church_register/members/models/member_entry_source.dart';
import 'package:church_register/members/screens/register_member_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLeaderService extends LeaderService {
  _FakeLeaderService({
    this.assignableLeaders = const [],
    this.leaderById,
  });

  final List<ChurchLeader> assignableLeaders;
  final ChurchLeader? leaderById;

  @override
  Future<List<ChurchLeader>> fetchAssignableLeaders({String? churchId}) async {
    return List<ChurchLeader>.from(assignableLeaders);
  }

  @override
  Future<List<ChurchLeader>> ensureLeaderInList({
    required List<ChurchLeader> leaders,
    required String leaderId,
    String? churchId,
  }) async {
    if (leaders.any((leader) => leader.id == leaderId)) {
      return leaders;
    }
    final extra = leaderById;
    if (extra != null && extra.id == leaderId) {
      return [...leaders, extra];
    }
    return leaders;
  }
}

ChurchLeader _sampleLeader({required String id}) {
  return ChurchLeader(
    id: id,
    firstName: 'Ana',
    lastName: 'García',
    mobilePhone: '1111111111',
    registeredAt: DateTime(2025, 1, 1),
    registeredBy: 'admin@test.com',
    gender: LeaderGender.mujer,
  );
}

ChurchMember _sampleMember({
  required String leaderId,
  bool isBaptized = false,
}) {
  return ChurchMember(
    id: 'member-1',
    firstName: 'Juan',
    lastName: 'Pérez',
    phone: '2222222222',
    birthDate: DateTime(1995, 5, 10),
    occupation: 'Estudiante',
    maritalStatus: MaritalStatus.soltero,
    entrySource: MemberEntrySource.evangelismo,
    formDate: DateTime(2026, 1, 1),
    registeredAt: DateTime(2026, 1, 1),
    registeredBy: 'admin@test.com',
    assignedLeaderId: leaderId,
    assignedLeaderName: 'Ana García',
    isNewBeliever: true,
    isBaptized: isBaptized,
  );
}

Future<void> _pumpRegisterMemberScreen(
  WidgetTester tester, {
  required Widget child,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

SwitchListTile _manualLeaderSwitch(WidgetTester tester) {
  final finder = find.widgetWithText(SwitchListTile, 'Elegir líder manualmente');
  expect(finder, findsOneWidget);
  return tester.widget<SwitchListTile>(finder);
}

SwitchListTile _baptizedSwitch(WidgetTester tester) {
  final finder = find.widgetWithText(SwitchListTile, 'Bautizado');
  expect(finder, findsOneWidget);
  return tester.widget<SwitchListTile>(finder);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('RegisterMemberScreen', () {
    testWidgets('inicia con el switch de elegir líder en false', (
      WidgetTester tester,
    ) async {
      await _pumpRegisterMemberScreen(
        tester,
        child: RegisterMemberScreen(
          registeredBy: 'leader@test.com',
          permissions: AppPermissions.fromRoles([AppUserRole.leader]),
          leaderService: _FakeLeaderService(),
        ),
      );

      expect(_manualLeaderSwitch(tester).value, isFalse);
    });

    testWidgets(
      'mantiene el switch en false aunque se pase actingLeaderId',
      (WidgetTester tester) async {
        const actingLeaderId = 'leader-acting';
        final actingLeader = _sampleLeader(id: actingLeaderId);

        await _pumpRegisterMemberScreen(
          tester,
          child: RegisterMemberScreen(
            registeredBy: 'leader@test.com',
            actingLeaderId: actingLeaderId,
            permissions: AppPermissions.fromRoles([AppUserRole.leader]),
            leaderService: _FakeLeaderService(
              assignableLeaders: [actingLeader],
              leaderById: actingLeader,
            ),
          ),
        );

        expect(_manualLeaderSwitch(tester).value, isFalse);
        expect(find.text('Ana García'), findsNothing);
      },
    );

    testWidgets(
      'inicia con el switch en false al editar un creyente con líder',
      (WidgetTester tester) async {
        const leaderId = 'leader-assigned';
        final leader = _sampleLeader(id: leaderId);

        await _pumpRegisterMemberScreen(
          tester,
          child: RegisterMemberScreen(
            registeredBy: 'admin@test.com',
            memberToEdit: _sampleMember(leaderId: leaderId),
            permissions: AppPermissions.fromRoles([AppUserRole.admin]),
            leaderService: _FakeLeaderService(
              assignableLeaders: [leader],
              leaderById: leader,
            ),
          ),
        );

        expect(_manualLeaderSwitch(tester).value, isFalse);
        expect(find.text('Ana García'), findsNothing);
      },
    );

    testWidgets('permite activar manualmente la elección de líder', (
      WidgetTester tester,
    ) async {
      await _pumpRegisterMemberScreen(
        tester,
        child: RegisterMemberScreen(
          registeredBy: 'leader@test.com',
          permissions: AppPermissions.fromRoles([AppUserRole.leader]),
          leaderService: _FakeLeaderService(
            assignableLeaders: [_sampleLeader(id: 'leader-1')],
          ),
        ),
      );

      expect(_manualLeaderSwitch(tester).value, isFalse);

      await tester.tap(find.text('Elegir líder manualmente'));
      await tester.pumpAndSettle();

      expect(_manualLeaderSwitch(tester).value, isTrue);
    });

    testWidgets('muestra el switch de bautizado al registrar', (
      WidgetTester tester,
    ) async {
      await _pumpRegisterMemberScreen(
        tester,
        child: RegisterMemberScreen(
          registeredBy: 'leader@test.com',
          permissions: AppPermissions.fromRoles([AppUserRole.leader]),
          leaderService: _FakeLeaderService(),
        ),
      );

      expect(_baptizedSwitch(tester).value, isFalse);
    });

    testWidgets('carga el estado de bautizado al editar', (
      WidgetTester tester,
    ) async {
      await _pumpRegisterMemberScreen(
        tester,
        child: RegisterMemberScreen(
          registeredBy: 'admin@test.com',
          memberToEdit: _sampleMember(
            leaderId: 'leader-1',
            isBaptized: true,
          ),
          permissions: AppPermissions.fromRoles([AppUserRole.admin]),
          leaderService: _FakeLeaderService(),
        ),
      );

      expect(_baptizedSwitch(tester).value, isTrue);
    });
  });
}
