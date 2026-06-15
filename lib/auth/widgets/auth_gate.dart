import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../church/services/church_service.dart';
import '../../home/screens/home_screen.dart';
import '../../leaders/services/leader_service.dart';
import '../../main.dart';
import '../../notifications/screens/leader_notifications_screen.dart';
import '../../notifications/services/push_notification_service.dart';
import '../models/app_user_role.dart';
import '../models/user_profile.dart';
import '../screens/login_screen.dart';
import 'access_enforcement_gate.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.authService, this.userProfileService});

  final AuthService? authService;
  final UserProfileService? userProfileService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _auth;
  late final UserProfileService _profileService;
  final _leaderService = LeaderService();
  final _churchService = ChurchService();
  final _pushService = PushNotificationService();
  UserSession? _session;
  String? _pushRegisteredUid;
  bool _loadingProfile = false;
  String? _profileError;
  String? _scheduledLoadUid;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService();
    _profileService = widget.userProfileService ?? UserProfileService();
  }

  void _scheduleProfileLoad(User user) {
    if (_session?.uid == user.uid) return;
    if (_loadingProfile) return;
    if (_scheduledLoadUid == user.uid) return;

    _scheduledLoadUid = user.uid;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduledLoadUid = null;
      if (!mounted) return;
      if (_auth.currentUser?.uid != user.uid) return;
      if (_session?.uid == user.uid) return;
      _loadProfile(user);
    });
  }

  void _resetSession() {
    if (_session == null && !_loadingProfile && _profileError == null) {
      return;
    }
    setState(() {
      _session = null;
      _loadingProfile = false;
      _profileError = null;
      _scheduledLoadUid = null;
      _pushRegisteredUid = null;
    });
  }

  void _configurePushForSession(UserSession session) {
    if (!session.permissions.isLeader) return;
    if (_pushRegisteredUid == session.uid) return;
    _pushRegisteredUid = session.uid;

    _pushService.initialize(onNotificationTap: _openNotificationsFromPush);
  }

  Future<void> _registerPushIfNeeded(UserSession session) async {
    if (!session.permissions.isLeader) return;
    await _pushService.registerForUser(session.uid);
    await _pushService.handleInitialMessage();
  }

  void _openNotificationsFromPush(RemoteMessage message) {
    final session = _session;
    if (session == null) return;

    rootNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => LeaderNotificationsScreen(session: session),
      ),
    );
  }

  void _syncAdminChurchListing(UserSession session) {
    if (!session.permissions.canViewChurchNotifications) return;
    final churchId = session.profile.churchId?.trim();
    if (churchId == null || churchId.isEmpty) return;
    unawaited(
      _profileService
          .ensureAdminListedOnChurch(uid: session.uid, churchId: churchId)
          .catchError((_) {}),
    );
  }

  Future<void> _loadProfile(User user) async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });

    try {
      final doc = await _profileService.fetchProfileDoc(user.uid);
      UserProfile profile;
      if (doc == null) {
        profile = UserProfile(
          roles: [AppUserRole.superAdmin],
          email: user.email,
        );
      } else {
        profile = UserProfile.fromFirestore(doc);
        if (profile.roles.isEmpty) {
          profile = UserProfile(
            roles: [AppUserRole.superAdmin],
            leaderId: profile.leaderId,
            churchId: profile.churchId,
            fullName: profile.fullName,
            email: profile.email ?? user.email,
          );
        }
      }

      if (!mounted) return;
      if (_auth.currentUser?.uid != user.uid) return;

      String? displayName;
      var churchId = profile.churchId;
      final leaderId = profile.leaderId;
      if (leaderId != null && leaderId.isNotEmpty) {
        final leader = await _leaderService.fetchLeaderById(leaderId);
        final name = leader?.fullName.trim();
        if (name != null && name.isNotEmpty) {
          displayName = name;
        }
        final leaderChurchId = leader?.churchId;
        if ((churchId == null || churchId.isEmpty) &&
            leaderChurchId != null &&
            leaderChurchId.isNotEmpty) {
          churchId = leaderChurchId;
        }
      }
      if (churchId != profile.churchId) {
        profile = UserProfile(
          roles: profile.roles,
          leaderId: profile.leaderId,
          churchId: churchId,
          fullName: profile.fullName,
          email: profile.email,
          isBlocked: profile.isBlocked,
        );
      }
      displayName ??= profile.fullName?.trim();
      if (displayName != null && displayName.isEmpty) {
        displayName = null;
      }

      final session = UserSession(
        uid: user.uid,
        email: user.email ?? user.uid,
        profile: profile,
        displayName: displayName,
      );
      setState(() {
        _session = session;
        _loadingProfile = false;
      });
      _configurePushForSession(session);
      _syncAdminChurchListing(session);
    } catch (_) {
      if (!mounted) return;
      if (_auth.currentUser?.uid != user.uid) return;
      final profileError = context.l10n.profileLoadError;
      setState(() {
        _profileError = profileError;
        _loadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted && _auth.currentUser == null) _resetSession();
          });
          return LoginScreen(authService: _auth);
        }

        if (_session?.uid != user.uid) {
          _scheduleProfileLoad(user);
        }

        if (_profileError != null) {
          final l10n = context.l10n;
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _profileError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _loadProfile(user),
                      child: Text(l10n.retry),
                    ),
                    TextButton(
                      onPressed: _auth.signOut,
                      child: Text(l10n.signOut),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (_session?.uid != user.uid || _loadingProfile) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = _session!;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _session?.uid != session.uid) return;
          _registerPushIfNeeded(session);
        });

        return AccessEnforcementGate(
          session: session,
          authService: _auth,
          userProfileService: _profileService,
          churchService: _churchService,
          child: HomeScreen(
            session: session,
            authService: _auth,
          ),
        );
      },
    );
  }
}
