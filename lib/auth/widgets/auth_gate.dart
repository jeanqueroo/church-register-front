import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../home/screens/home_screen.dart';
import '../models/app_user_role.dart';
import '../models/user_profile.dart';
import '../screens/login_screen.dart';
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
  UserSession? _session;
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
    });
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
          roles: [AppUserRole.admin],
          email: user.email,
        );
      } else {
        profile = UserProfile.fromFirestore(doc);
        if (profile.roles.isEmpty) {
          profile = UserProfile(
            roles: [AppUserRole.admin],
            leaderId: profile.leaderId,
            fullName: profile.fullName,
            email: profile.email ?? user.email,
          );
        }
      }

      if (!mounted) return;
      if (_auth.currentUser?.uid != user.uid) return;
      setState(() {
        _session = UserSession(
          uid: user.uid,
          email: user.email ?? user.uid,
          profile: profile,
        );
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_auth.currentUser?.uid != user.uid) return;
      setState(() {
        _profileError = 'No se pudo cargar tu perfil de usuario.';
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
                      child: const Text('Reintentar'),
                    ),
                    TextButton(
                      onPressed: _auth.signOut,
                      child: const Text('Cerrar sesión'),
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

        return HomeScreen(
          session: _session!,
          authService: _auth,
        );
      },
    );
  }
}
