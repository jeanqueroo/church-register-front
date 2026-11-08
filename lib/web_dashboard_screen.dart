import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../auth/models/user_profile.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// IMPORTAMOS EL SERVICIO DEL CELULAR Y LÍDERES
import '../home/services/home_dashboard_service.dart';
import 'leaders/services/leader_service.dart';
import 'leaders/screens/leader_assigned_members_screen.dart';

// IMPORTAMOS LOS SERVICIOS DE NOTIFICACIONES
import '../notifications/services/admin_notification_service.dart';
import '../notifications/services/leader_notification_service.dart';

// IMPORTAMOS TODAS LAS PANTALLAS
import '../auth/screens/account_hub_screen.dart';
import '../notifications/screens/admin_notifications_screen.dart';
import '../notifications/screens/leader_notifications_screen.dart';
import 'members/screens/members_list_screen.dart';
import 'leaders/screens/leaders_list_screen.dart';
import 'cells/screens/cells_list_screen.dart';
import 'members/models/members_list_filter.dart';

import 'dashboard/screens/birthdays_screen.dart';

import 'members/screens/register_member_screen.dart';
import 'members/screens/members_by_leader_screen.dart';
import 'leaders/screens/register_leader_screen.dart';
import 'supervisors/screens/supervisor_leader_assignments_screen.dart';
import 'supervisors/screens/supervisor_my_leaders_screen.dart';
import 'dashboard/screens/leader_dashboard_screen.dart';
import 'cells/screens/register_cell_screen.dart';
import 'cells/screens/cells_over_capacity_screen.dart';
import 'cells/screens/cell_absence_by_leader_screen.dart';
import 'dashboard/screens/cell_dashboard_screen.dart';
import 'baptism/screens/baptism_calendar_screen.dart';
import 'dashboard/screens/baptism_dashboard_screen.dart';
import 'dashboard/screens/offering_dashboard_screen.dart';
import 'dashboard/screens/visits_dashboard_screen.dart';
import 'dashboard/screens/pastoral_dashboard_screen.dart';
import 'cells/screens/my_assigned_cells_screen.dart';

class WebDashboardScreen extends StatefulWidget {
  final UserSession session;
 
  const WebDashboardScreen({super.key, required this.session});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  bool _isMenuOpen = true;
  int _selectedIndex = 0;

  int _countMiembros = 0;
  int _countNuevos = 0;
  int _countLideres = 0;
  int _countCelulas = 0;
  int _countBautismos = 0;

  final _dashboardService = HomeDashboardService();
  final _adminNotificationService = AdminNotificationService();
  final _leaderNotificationService = LeaderNotificationService();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<String?> _getChurchLogoUrl() async {
    final churchId = widget.session.profile.churchId;
    if (churchId == null || churchId.isEmpty) return null;

    try {
      final doc = await FirebaseFirestore.instance.collection('churches').doc(churchId).get();
      if (doc.exists) {
        final data = doc.data();
        final logoGuardado = data?['logoUrl'] as String?;
        if (logoGuardado != null && logoGuardado.isNotEmpty) return logoGuardado;
      }
      final bucket = 'church-register-pro.firebasestorage.app';
      return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/church_profiles%2F$churchId%2Flogo.png?alt=media';
    } catch (e) {
      print("DEBUG: Error al buscar logo: $e");
    }
    return null;
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await _dashboardService.loadForSession(widget.session);
      if (mounted) {
        setState(() {
          _countMiembros = data.memberCount;
          _countNuevos = data.newBelieverCount;
          _countLideres = data.leaderCount ?? 0;
          _countCelulas = data.cellCount ?? 0;
          _countBautismos = data.baptismCount ?? 0;
        });
      }
    } catch (e) {
      print("Error cargando los datos del dashboard: $e");
    }
  }

  Widget _buildNotificationBell() {
    final p = widget.session.permissions;
    final uid = widget.session.uid;
    final leaderId = widget.session.profile.leaderId;

    if (p.canViewChurchNotifications) {
      return StreamBuilder<int>(
        stream: _adminNotificationService.watchUnreadCountForUser(uid),
        builder: (context, snapshot) {
          final unread = snapshot.data ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 9 ? '9+' : '$unread'),
                child: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminNotificationsScreen(session: widget.session)));
              },
            ),
          );
        },
      );
    }
   
    if (p.canViewLeaderNotifications && leaderId != null && leaderId.isNotEmpty) {
      return StreamBuilder<int>(
        stream: _leaderNotificationService.watchUnreadCountForLeader(leaderId),
        builder: (context, snapshot) {
          final unread = snapshot.data ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 9 ? '9+' : '$unread'),
                child: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LeaderNotificationsScreen(session: widget.session)));
              },
            ),
          );
        },
      );
    }

    return const Padding(
      padding: EdgeInsets.only(right: 8.0),
      child: Icon(Icons.notifications_none, color: Colors.white, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.session.permissions;
    final isAdmin = p.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isMenuOpen ? 250 : 0,
            color: const Color(0xFF0D2750),
            child: _isMenuOpen
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        FutureBuilder<String?>(
                          future: _getChurchLogoUrl(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(width: 90, height: 90, child: Center(child: CircularProgressIndicator(color: Colors.white)));
                            }
                            if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                              return ClipOval(
                                child: Image.network(snapshot.data!, width: 90, height: 90, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.water_drop, size: 60, color: Colors.white)),
                              );
                            }
                            return const Icon(Icons.water_drop, size: 60, color: Colors.white);
                          },
                        ),
                        const SizedBox(height: 15),
                        const Text('Manantial De\nBendiciones Central', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.3)),
                        const SizedBox(height: 30),
                       
                        _buildSidebarItem(icon: Icons.home, title: 'Inicio', index: 0, onTap: () => setState(() => _selectedIndex = 0)),
                       
                        if (isAdmin) ...[
                          _buildSidebarItem(icon: Icons.people, title: 'Creyentes', index: 1, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _CreyentesOptionsPanel(session: widget.session)))),
                          _buildSidebarItem(icon: Icons.stars, title: 'Líderes', index: 2, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _LideresOptionsPanel(session: widget.session)))),
                          _buildSidebarItem(icon: Icons.house, title: 'Células', index: 3, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _CelulasOptionsPanel(session: widget.session)))),
                        ],
                       
                        _buildSidebarItem(icon: Icons.more_horiz, title: 'Más', index: 4, onTap: () => _showMoreMenu(context), forceUnselected: true),

                        const SizedBox(height: 40),
                        const Divider(color: Colors.white24, height: 1),
                       
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.redAccent),
                          title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 65,
                  color: const Color(0xFF0D2750),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.menu, color: Colors.white, size: 28), onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen)),
                      const Spacer(),
                      _buildNotificationBell(),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => AccountHubScreen(session: widget.session)));
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: widget.session.profile.photoUrl != null && widget.session.profile.photoUrl!.isNotEmpty ? NetworkImage(widget.session.profile.photoUrl!) : null,
                            child: widget.session.profile.photoUrl == null || widget.session.profile.photoUrl!.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildCurrentView()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenMoreMenu(session: widget.session),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildCurrentView() {
    return _buildDashboardInicio();
  }

  Widget _buildDashboardInicio() {
    final p = widget.session.permissions;
    final isAdmin = p.isAdmin;
    final isSupervisor = p.canViewMySupervisedLeaders;

    if (isAdmin) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 30),
            const Text('Resumen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 15),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildSummaryCard('$_countMiembros', 'Miembros', 'Total de miembros activos', Icons.group, const Color(0xFF1D4ED8), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MembersListScreen(registeredBy: widget.session.uid, permissions: p, filter: MembersListFilter.activeChurchMembers))))),
                  const SizedBox(width: 15),
                  Expanded(child: _buildSummaryCard('$_countNuevos', 'Nuevo creyentes', 'Nuevos creyentes registrados', Icons.person_add, const Color(0xFF15803D), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MembersListScreen(registeredBy: widget.session.uid, permissions: p, filter: MembersListFilter.newBelievers))))),
                  const SizedBox(width: 15),
                  Expanded(child: _buildSummaryCard('$_countLideres', 'Líderes', 'Líderes registrados y activos', Icons.military_tech, const Color(0xFF7E22CE), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LeadersListScreen(registeredBy: widget.session.uid, permissions: p))))),
                  const SizedBox(width: 15),
                  Expanded(child: _buildSummaryCard('$_countCelulas', 'Células', 'Células activas', Icons.house, const Color(0xFFC2410C), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CellsListScreen(registeredBy: widget.session.uid, permissions: p))))),
                  const SizedBox(width: 15),
                  Expanded(child: _buildSummaryCard('$_countBautismos', 'Bautismos', 'Bautismos programados', Icons.water_drop, const Color(0xFF0F766E), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BaptismCalendarScreen(registeredBy: widget.session.uid, churchId: widget.session.profile.churchId, actingLeaderId: widget.session.profile.leaderId, permissions: p))))),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text('Acciones rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 15),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 15,
              crossAxisSpacing: 20,
              childAspectRatio: 4.5,
              children: [
                _buildActionButton(icon: Icons.person_add, title: 'Ver nuevos creyentes', subtitle: 'Lista de nuevos creyentes', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _CreyentesOptionsPanel(session: widget.session)))),
                _buildActionButton(icon: Icons.group_add, title: 'Registro de líderes', subtitle: 'Datos del liderazgo', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _LideresOptionsPanel(session: widget.session)))),
                _buildActionButton(icon: Icons.group, title: 'Ver líderes', subtitle: 'Lista de líderes registrados', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _LideresOptionsPanel(session: widget.session)))),
                _buildActionButton(icon: Icons.add_circle_outline, title: 'Crear célula', subtitle: 'Registrar nuevo grupo', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _CelulasOptionsPanel(session: widget.session)))),
                _buildActionButton(icon: Icons.list_alt, title: 'Ver células', subtitle: 'Lista de células', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _CelulasOptionsPanel(session: widget.session)))),
              ],
            ),
          ],
        ),
      );
    } else if (isSupervisor) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 20),
            const Text('Resumen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 15),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                SizedBox(width: 300, child: _buildSummaryCard('$_countMiembros', 'Mis discípulos', 'En tu célula asignada', Icons.people, const Color(0xFF1D4ED8), onTap: () {})),
                SizedBox(width: 300, child: _buildSummaryCard('$_countNuevos', 'Mis nuevos creyentes', 'Asignados a tu liderazgo', Icons.person_add, const Color(0xFF15803D), onTap: () {})),
                SizedBox(width: 300, child: _buildSummaryCard('$_countLideres', 'Mis líderes asignados', 'Líderes que supervisas', Icons.military_tech, const Color(0xFF7E22CE), onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => SupervisorMyLeadersScreen(session: widget.session)));
                })),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Hoy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cumpleaños del día de mi célula', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Text('No hay cumpleaños hoy en tu célula.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('Acciones rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                SizedBox(width: 300, child: _buildActionButton(icon: Icons.person_add_alt_1, title: 'Registro de nuevo creyente', subtitle: 'Formulario de nuevo creyente', onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterMemberScreen(registeredBy: widget.session.uid, churchId: widget.session.profile.churchId, permissions: p)));
                })),
                SizedBox(width: 300, child: _buildActionButton(icon: Icons.person_add, title: 'Registrar discípulo nuevo', subtitle: 'Agregar un discípulo a tu célula', onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: widget.session, registeredBy: widget.session.uid)));
                })),
                SizedBox(width: 300, child: _buildActionButton(icon: Icons.calendar_today, title: 'Registrar asistencia', subtitle: 'Selecciona tu célula para registrar asistencia', onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: widget.session, registeredBy: widget.session.uid, mode: MyAssignedCellsMode.attendance)));
                })),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 20),
            const Text('Resumen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildSummaryCard('$_countMiembros', 'Mis discípulos', 'En tu célula asignada', Icons.people, const Color(0xFF1D4ED8), onTap: () {})),
                  const SizedBox(width: 15),
                  Expanded(child: _buildSummaryCard('$_countNuevos', 'Mis nuevos creyentes', 'Asignados a tu liderazgo', Icons.person_add, const Color(0xFF15803D), onTap: () {})),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text('Hoy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cumpleaños del día de mi célula', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Text('No hay cumpleaños hoy en tu célula.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text('Acciones rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 10),
            _buildActionButton(icon: Icons.person_add_alt_1, title: 'Registro de nuevo creyente', subtitle: 'Formulario de nuevo creyente', onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterMemberScreen(registeredBy: widget.session.uid, churchId: widget.session.profile.churchId, permissions: p)));
            }),
            const SizedBox(height: 10),
            _buildActionButton(icon: Icons.person_add, title: 'Registrar discípulo nuevo', subtitle: 'Agregar un discípulo a tu célula', onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: widget.session, registeredBy: widget.session.uid)));
            }),
            const SizedBox(height: 10),
            _buildActionButton(icon: Icons.calendar_today, title: 'Registrar asistencia', subtitle: 'Selecciona tu célula para registrar asistencia', onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: widget.session, registeredBy: widget.session.uid, mode: MyAssignedCellsMode.attendance)));
            }),
            const SizedBox(height: 40),
          ],
        ),
      );
    }
  }

  Widget _buildSidebarItem({required IconData icon, required String title, required int index, required VoidCallback onTap, bool forceUnselected = false}) {
    final isSelected = _selectedIndex == index && !forceUnselected;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: isSelected ? const Color(0xFF1E4B8F) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(color: Color(0xFF0D2750), shape: BoxShape.circle),
            child: ClipOval(
              child: FutureBuilder<String?>(
                future: _getChurchLogoUrl(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                    return Padding(padding: const EdgeInsets.all(8.0), child: Image.network(snapshot.data!, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.water_drop, color: Colors.white, size: 30)));
                  }
                  return const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.water_drop, color: Colors.white, size: 30));
                },
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenido, ${widget.session.resolvedDisplayName ?? widget.session.email}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text('Gracias por liderar con propósito.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String value, String title, String desc, IconData icon, Color color, {required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 5))]
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.25), color.withOpacity(0.50)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.6), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 24)),
                  const SizedBox(height: 15),
                  Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 5),
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 5),
                  Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF059669), size: 22)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreyentesOptionsPanel extends StatelessWidget {
  final UserSession session;

  const _CreyentesOptionsPanel({required this.session});

  @override
  Widget build(BuildContext context) {
    final p = session.permissions;
    return Scaffold(
      backgroundColor: const Color(0xFF041E42),
      appBar: AppBar(
        backgroundColor: const Color(0xFF041E42),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF29D2F5)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Panel de Opciones', style: TextStyle(color: Color(0xFF29D2F5), fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('REGISTRO DE CREYENTES'),
            const SizedBox(height: 15),
            _buildOptionItem(context, icon: Icons.person_add_alt_1, title: 'Nuevo creyente', description: 'Registrar persona', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterMemberScreen(registeredBy: session.uid, churchId: session.profile.churchId, permissions: p)));
            }),
            _buildOptionItem(context, icon: Icons.people_outline, title: 'Ver miembros', description: 'Lista completa', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MembersListScreen(registeredBy: session.uid, permissions: p, filter: MembersListFilter.activeChurchMembers)));
            }),
            _buildOptionItem(context, icon: Icons.person_search, title: 'Nuevos creyentes', description: 'Ingresos recientes', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MembersListScreen(registeredBy: session.uid, permissions: p, filter: MembersListFilter.newBelievers)));
            }),
            _buildOptionItem(context, icon: Icons.person_outline, title: 'Nuevos por líder', description: 'Filtrado discipulado', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MembersByLeaderScreen(registeredBy: session.uid, permissions: p)));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF0A3370), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF29D2F5), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildOptionItem(BuildContext context, {required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF0A3370),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFF1A66C2), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(description, style: const TextStyle(fontSize: 13, color: Color(0xFFA0C1E8))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF29D2F5), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LideresOptionsPanel extends StatelessWidget {
  final UserSession session;

  const _LideresOptionsPanel({required this.session});

  @override
  Widget build(BuildContext context) {
    final p = session.permissions;
    return Scaffold(
      backgroundColor: const Color(0xFF041E42),
      appBar: AppBar(
        backgroundColor: const Color(0xFF041E42),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF29D2F5)), onPressed: () => Navigator.pop(context)),
        title: const Text('Panel de Opciones', style: TextStyle(color: Color(0xFF29D2F5), fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('REGISTRO DE LÍDERES'),
            const SizedBox(height: 15),
            _buildOptionItem(context, icon: Icons.person_add, title: 'Crear líder', description: 'Añadir nuevo líder', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterLeaderScreen(registeredBy: session.uid, churchId: session.profile.churchId, permissions: p)));
            }),
            _buildOptionItem(context, icon: Icons.group_outlined, title: 'Ver líderes', description: 'Lista de líderes', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LeadersListScreen(registeredBy: session.uid, permissions: p)));
            }),
            _buildOptionItem(context, icon: Icons.manage_accounts, title: 'Por supervisor', description: 'Asignación y gestión', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SupervisorLeaderAssignmentsScreen(session: session)));
            }),
            _buildOptionItem(context, icon: Icons.bar_chart, title: 'Estadísticas', description: 'Métricas de líderes', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LeaderDashboardScreen(session: session)));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF0A3370), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF29D2F5), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildOptionItem(BuildContext context, {required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF0A3370),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFF1A66C2), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(description, style: const TextStyle(fontSize: 13, color: Color(0xFFA0C1E8))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF29D2F5), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CelulasOptionsPanel extends StatelessWidget {
  final UserSession session;

  const _CelulasOptionsPanel({required this.session});

  @override
  Widget build(BuildContext context) {
    final p = session.permissions;
    return Scaffold(
      backgroundColor: const Color(0xFF041E42),
      appBar: AppBar(
        backgroundColor: const Color(0xFF041E42),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF29D2F5)), onPressed: () => Navigator.pop(context)),
        title: const Text('Panel de Opciones', style: TextStyle(color: Color(0xFF29D2F5), fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('CÉLULA'),
            const SizedBox(height: 15),
            _buildOptionItem(context, icon: Icons.add_circle_outline, title: 'Crear célula', description: 'Registrar nuevo grupo', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterCellScreen(registeredBy: session.uid, churchId: session.profile.churchId, permissions: p)));
            }),
            _buildOptionItem(context, icon: Icons.list_alt, title: 'Ver células', description: 'Listado general', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CellsListScreen(registeredBy: session.uid, permissions: p)));
            }),
            _buildOptionItem(context, icon: Icons.fact_check, title: 'Asistencia', description: 'Reporte discípulos', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CellsListScreen(registeredBy: session.uid, permissions: p, mode: CellsListMode.attendanceReport)));
            }),
            _buildOptionItem(context, icon: Icons.warning_amber, title: 'Inasistencias', description: 'Alertas de ausencias', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CellAbsenceByLeaderScreen(churchId: session.profile.churchId, permissions: p)));
            }),
            _buildOptionItem(context, icon: Icons.call_split, title: 'Para multiplicar', description: 'Límite de capacidad', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CellsOverCapacityScreen(registeredBy: session.uid, churchId: session.profile.churchId, permissions: p)));
            }),
            _buildOptionItem(context, icon: Icons.bar_chart, title: 'Estadísticas', description: 'Métricas de células', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CellDashboardScreen(session: session)));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF0A3370), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF29D2F5), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildOptionItem(BuildContext context, {required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF0A3370),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFF1A66C2), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(description, style: const TextStyle(fontSize: 13, color: Color(0xFFA0C1E8))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF29D2F5), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenMoreMenu extends StatelessWidget {
  final UserSession session;

  const _FullScreenMoreMenu({required this.session});

  @override
  Widget build(BuildContext context) {
    final isAdmin = session.permissions.isAdmin;
    final isSupervisor = session.permissions.canViewMySupervisedLeaders;

    return Scaffold(
      backgroundColor: const Color(0xFF041E42),
      appBar: AppBar(
        backgroundColor: const Color(0xFF041E42),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF29D2F5)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Panel de Opciones', style: TextStyle(color: Color(0xFF29D2F5), fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: isAdmin
          ? _buildAdminMenu(context)
          : isSupervisor
              ? _buildSupervisorMenu(context)
              : _buildLeaderMenu(context),
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: _buildColumn(title: 'BAUTISMO', children: [
            _buildVerticalItem(context, icon: Icons.cake, title: 'Cumpleaños', description: 'Cumpleaños del día', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BirthdaysScreen(session: session)))),
            _buildVerticalItem(context, icon: Icons.calendar_month, title: 'Calendario', description: 'Programación fechas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BaptismCalendarScreen(registeredBy: session.uid, churchId: session.profile.churchId, actingLeaderId: session.profile.leaderId, permissions: session.permissions)))),
            _buildVerticalItem(context, icon: Icons.bar_chart, title: 'Estadísticas', description: 'Reporte bautizados', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BaptismDashboardScreen(session: session)))),
          ])),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: _buildColumn(title: 'ADMINISTRACIÓN', children: [
            _buildVerticalItem(context, icon: Icons.analytics, title: 'Reportes', description: 'Balances del mes', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _ReportsScreen(session: session)))),
            _buildVerticalItem(context, icon: Icons.volunteer_activism, title: 'Ofrendas', description: 'Gestión finanzas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OfferingDashboardScreen(session: session)))),
            _buildVerticalItem(context, icon: Icons.dashboard, title: 'Visitas', description: 'Métricas de visitas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VisitsDashboardScreen(session: session)))),
            _buildVerticalItem(context, icon: Icons.favorite_border, title: 'Pastoral', description: 'Métricas generales', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PastoralDashboardScreen(session: session)))),
          ])),
        ],
      ),
    );
  }

  Widget _buildSupervisorMenu(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: _buildColumn(title: 'REGISTRO DE NUEVOS CREYENTES', children: [
            _buildVerticalItem(context, icon: Icons.person_add_alt_1, title: 'Nuevo creyente', description: 'Registrar persona', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterMemberScreen(registeredBy: session.uid, churchId: session.profile.churchId, permissions: session.permissions)))),
            _buildVerticalItem(context, icon: Icons.people_outline, title: 'Mis nuevos creyentes', description: 'Lista asignados a ti', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MembersListScreen(registeredBy: session.uid, permissions: session.permissions, filter: MembersListFilter.newBelievers)))),
            _buildVerticalItem(context, icon: Icons.account_tree_outlined, title: 'Mis líderes asignados', description: 'Líderes que supervisas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SupervisorMyLeadersScreen(session: session)))),
          ])),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: _buildColumn(title: 'CÉLULA', children: [
            _buildVerticalItem(context, icon: Icons.people_alt_outlined, title: 'Mi célula', description: 'Ver mi grupo asignado', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: session, registeredBy: session.uid)))),
            _buildVerticalItem(context, icon: Icons.event_available_outlined, title: 'Registrar asistencia', description: 'Pasar lista de mi célula', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: session, registeredBy: session.uid, mode: MyAssignedCellsMode.attendance)))),
            _buildVerticalItem(context, icon: Icons.fact_check_outlined, title: 'Asistencia de discípulos', description: 'Reporte de mi célula', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: session, registeredBy: session.uid, mode: MyAssignedCellsMode.attendanceReport)))),
            _buildVerticalItem(context, icon: Icons.history, title: 'Mis asistencias', description: 'Historial de asistencia', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: session, registeredBy: session.uid, mode: MyAssignedCellsMode.attendanceManage)))),
          ])),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: _buildColumn(title: 'BAUTISMO', children: [
            _buildVerticalItem(context, icon: Icons.calendar_month_outlined, title: 'Calendario de bautismo', description: 'Programación de fechas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BaptismCalendarScreen(registeredBy: session.uid, churchId: session.profile.churchId, actingLeaderId: session.profile.leaderId, permissions: session.permissions)))),
            _buildVerticalItem(context, icon: Icons.bar_chart, title: 'Dashboard de visitas', description: 'Métricas de visitas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VisitsDashboardScreen(session: session)))),
            _buildVerticalItem(context, icon: Icons.favorite_border, title: 'Dashboard pastoral', description: 'Métricas generales', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PastoralDashboardScreen(session: session)))),
          ])),
        ],
      ),
    );
  }

  Widget _buildLeaderMenu(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: _buildColumn(title: 'REGISTRO DE NUEVOS CREYENTES', children: [
            _buildVerticalItem(context, icon: Icons.person_add_alt_1, title: 'Nuevo creyente', description: 'Registrar persona', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterMemberScreen(registeredBy: session.uid, churchId: session.profile.churchId, permissions: session.permissions)))),
            _buildVerticalItem(context, icon: Icons.people_outline, title: 'Mis nuevos creyentes', description: 'Lista asignados a ti', onTap: () async {
              final leaderId = session.profile.leaderId;
              if (leaderId != null && leaderId.isNotEmpty) {
                final leaderService = LeaderService();
                final leader = await leaderService.fetchLeaderById(leaderId);
                if (leader != null && context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LeaderAssignedMembersScreen(
                    leader: leader, registeredBy: session.uid, permissions: session.permissions,
                  )));
                }
              }
            }),
          ])),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: _buildColumn(title: 'CÉLULA', children: [
            _buildVerticalItem(context, icon: Icons.people_alt, title: 'Mi célula', description: 'Ver mi grupo asignado', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: session, registeredBy: session.uid)))),
            _buildVerticalItem(context, icon: Icons.event_available, title: 'Registrar asistencia', description: 'Pasar lista de mi célula', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: session, registeredBy: session.uid, mode: MyAssignedCellsMode.attendance)))),
            _buildVerticalItem(context, icon: Icons.fact_check, title: 'Asistencia de discípulos', description: 'Reporte de mi célula', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: session, registeredBy: session.uid, mode: MyAssignedCellsMode.attendanceReport)))),
            _buildVerticalItem(context, icon: Icons.history, title: 'Mis asistencias', description: 'Historial de asistencia', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyAssignedCellsScreen(session: session, registeredBy: session.uid, mode: MyAssignedCellsMode.attendanceManage)))),
          ])),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: _buildColumn(title: 'BAUTISMO', children: [
            _buildVerticalItem(context, icon: Icons.calendar_month, title: 'Calendario de bautismo', description: 'Programación de fechas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BaptismCalendarScreen(registeredBy: session.uid, churchId: session.profile.churchId, actingLeaderId: session.profile.leaderId, permissions: session.permissions)))),
          ])),
        ],
      ),
    );
  }

  Widget _buildColumn({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryTitle(title),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3370),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF29D2F5), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalItem(BuildContext context, {required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF0A3370),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFF1A66C2), shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 20)
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFFA0C1E8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF29D2F5), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



// ==============================================================================
// PANTALLA: CENTRO DE REPORTES
// ==============================================================================
class _ReportsScreen extends StatefulWidget {
  final UserSession session;
  const _ReportsScreen({required this.session});

  @override
  State<_ReportsScreen> createState() => _ReportsScreenState();
}
class _ReportsScreenState extends State<_ReportsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  int _totalIglesia = 0;
  int _totalMiembros = 0; 
  int _totalLideres = 0;
  int _totalVoluntarios = 0;
  int _bautismosRealizados = 0;
  int _lideresBloqueados = 0;
  int _nuevosCreyentesMes = 0; 
  int _nuevosEnCelulaMes = 0; 

  List<FlSpot> _chartSpots = [];
  List<String> _chartMonths = [];

  List<Map<String, dynamic>> _topCells = [];
  List<Map<String, dynamic>> _riskCells = [];
  List<Map<String, dynamic>> _blockedLeadersDetails = [];
  List<Map<String, dynamic>> _newBelieversDetails = []; 
  List<Map<String, dynamic>> _newInCellDetails = []; 
  List<Map<String, dynamic>> _volunteersDetails = [];

  final _dashboardService = HomeDashboardService(); 

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    
    final churchId = widget.session.profile.churchId;
    if (churchId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

    int tTotalIglesia = 0;
    int tMiembrosEnCelula = 0; 
    int tLideres = 0;
    int tVoluntarios = 0;
    int tBautismos = 0;
    int tBloqueados = 0;
    int tNuevosCreyentesMes = 0;
    int tNuevosEnCelulaMes = 0;
    
    List<Map<String, dynamic>> tBlockedLeadersDetails = [];
    List<Map<String, dynamic>> tNewBelieversDetails = [];
    List<Map<String, dynamic>> tNewInCellDetails = [];
    List<Map<String, dynamic>> tVolunteersDetails = [];
    
    List<FlSpot> tChartSpots = [];
    List<String> tChartMonths = [];

    // 1. TOTAL IGLESIA
    try {
      final data = await _dashboardService.loadForSession(widget.session);
      tMiembrosEnCelula = data.memberCount; 
      tLideres = data.leaderCount ?? 0;     
      tTotalIglesia = tMiembrosEnCelula + tLideres;
    } catch (e) { debugPrint("Error en Total Iglesia: $e"); }

    // 2. VOLUNTARIOS (Solo asistentes, NO líderes consolidados)
try {
  final snapVoluntarios = await FirebaseFirestore.instance
      .collection('leaders')
      .where('churchId', isEqualTo: churchId)
      .get();

  for (var doc in snapVoluntarios.docs) {
    final data = doc.data();
    
    String roleString = data['role']?.toString().toLowerCase() ?? '';
    
    // 1. Detectar si YA ES UN LÍDER CONSOLIDADOS
    // (Ajusta estas palabras clave si en tu app usas otros nombres para líderes)
    bool esLiderConsolidado = roleString.contains('líder') || 
                              roleString.contains('lider') || 
                              data['isLeader'] == true ||
                              data['isConsolidated'] == true;

    // 2. Detectar si ES VOLUNTARIO (y no un líder)
    bool esVoluntario = (data['isVolunteer'] == true || roleString.contains('voluntario')) && !esLiderConsolidado;

    if (esVoluntario) {
      // Buscamos la fecha en que se convirtió en voluntario
      DateTime? fechaVoluntario;
      if (data['volunteerSince'] != null) {
        fechaVoluntario = (data['volunteerSince'] as Timestamp).toDate();
      } else if (data['updatedAt'] != null) {
        fechaVoluntario = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['registeredAt'] != null) {
        fechaVoluntario = (data['registeredAt'] as Timestamp).toDate();
      }

      // Si la fecha cae dentro del mes del reporte
      if (fechaVoluntario != null && 
          fechaVoluntario.isAfter(startDate) && 
          fechaVoluntario.isBefore(endDate)) {
          
        tVoluntarios++;
        String nombre = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        if (nombre.isEmpty) nombre = data['fullName'] ?? data['name'] ?? 'Sin nombre';
        
        tVolunteersDetails.add({
          'Nombre': nombre,
          'Teléfono': data['mobilePhone'] ?? data['phone'] ?? 'Sin teléfono',
          'Fecha Voluntario': '${fechaVoluntario.day}/${fechaVoluntario.month}/${fechaVoluntario.year}',
        });
      }
    }
  }
} catch (e) { 
  debugPrint("Error en Voluntarios: $e"); 
}

    // 3. BAUTISMOS (Desactivado)
    tBautismos = 0;

    // 4. LÍDERES BLOQUEADOS
    try {
      final snap = await FirebaseFirestore.instance.collection('leaders')
          .where('churchId', isEqualTo: churchId).where('isBlocked', isEqualTo: true).get();
      
      for (var doc in snap.docs) {
        final data = doc.data();
        DateTime? fechaBloqueo = data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : (data['blockedAt'] != null ? (data['blockedAt'] as Timestamp).toDate() : null);

        if (fechaBloqueo != null && fechaBloqueo.isAfter(startDate) && fechaBloqueo.isBefore(endDate)) {
          tBloqueados++;
          String nombre = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
          if (nombre.isEmpty) nombre = data['fullName'] ?? data['name'] ?? 'Sin nombre';
          tBlockedLeadersDetails.add({
            'Nombre': nombre,
            'Teléfono': data['mobilePhone'] ?? data['phone'] ?? 'Sin teléfono',
            'Fecha Bloqueo': '${fechaBloqueo.day}/${fechaBloqueo.month}/${fechaBloqueo.year}',
            'Estado': 'Bloqueado',
          });
        }
      }
    } catch (e) { debugPrint("Error en Bloqueados: $e"); }

    // 5. NUEVOS CREYENTES Y GRÁFICA
    try {
      final cellsNamesSnap = await FirebaseFirestore.instance.collection('cells').where('churchId', isEqualTo: churchId).get();
      Map<String, String> cellNamesMap = { for (var d in cellsNamesSnap.docs) d.id: d.data()['name'] ?? 'Sin nombre' };

      final snap = await FirebaseFirestore.instance.collection('members')
          .where('churchId', isEqualTo: churchId)
          .where('isNewBeliever', isEqualTo: true) 
          .where('registeredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('registeredAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
          
      for (var doc in snap.docs) {
        final data = doc.data();
        DateTime? fechaRegistro = data['registeredAt'] != null ? (data['registeredAt'] as Timestamp).toDate() : null;
        String nombre = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        if (nombre.isEmpty) nombre = data['fullName'] ?? data['name'] ?? 'Sin nombre';

        String idRealCelula = '';
        dynamic celdaRaw = data['cellId'] ?? 
                           data['assignedCellId'] ?? 
                           data['cell'] ?? 
                           data['celula'] ?? 
                           data['cell_id'] ?? 
                           data['assignedCell'];

        if (celdaRaw != null) {
          if (celdaRaw is String) {
            idRealCelula = celdaRaw.trim();
          } else if (celdaRaw is DocumentReference) {
            idRealCelula = celdaRaw.id.trim(); 
          }
        }

        bool estaEnCelula = idRealCelula.isNotEmpty && idRealCelula.length > 3;
        
        if (!estaEnCelula) {
          // SIN CÉLULA
          tNuevosCreyentesMes++;
          tNewBelieversDetails.add({
            'Nombre': nombre,
            'Teléfono': data['mobilePhone'] ?? data['phone'] ?? 'Sin teléfono',
            'Fecha Registro': fechaRegistro != null ? '${fechaRegistro.day}/${fechaRegistro.month}/${fechaRegistro.year}' : 'Sin fecha',
            'En Célula': 'No',
          });
        } else {
          // EN CÉLULA
          tNuevosEnCelulaMes++;
          tNewInCellDetails.add({
            'Nombre': nombre,
            'Teléfono': data['mobilePhone'] ?? data['phone'] ?? 'Sin teléfono',
            'Fecha Registro': fechaRegistro != null ? '${fechaRegistro.day}/${fechaRegistro.month}/${fechaRegistro.year}' : 'Sin fecha',
            'Célula': cellNamesMap[idRealCelula] ?? 'Célula Desconocida',
          });
        }
      }

      // Gráfica
      for (int i = 5; i >= 0; i--) {
        DateTime d = DateTime(_selectedMonth.year, _selectedMonth.month - i, 1);
        DateTime start = DateTime(d.year, d.month, 1);
        DateTime end = DateTime(d.year, d.month + 1, 0, 23, 59, 59);

        final snapChart = await FirebaseFirestore.instance.collection('members')
            .where('churchId', isEqualTo: churchId)
            .where('isNewBeliever', isEqualTo: true) 
            .where('registeredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('registeredAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();
            
        int count = snapChart.docs.length;
        tChartSpots.add(FlSpot((5 - i).toDouble(), count.toDouble()));
        tChartMonths.add(_getShortMonthName(d.month));
      }

    } catch (e) { debugPrint("Error en Nuevos Creyentes/Gráfica: $e"); }

    // 6. CÉLULAS
    try {
      final leadersSnap = await FirebaseFirestore.instance.collection('leaders').where('churchId', isEqualTo: churchId).get();
      
      Map<String, String> phoneById = {};
      Map<String, String> phoneByName = {};

      for (var doc in leadersSnap.docs) {
        final lData = doc.data();
        String phone = lData['mobilePhone'] ?? lData['phone'] ?? 'Sin teléfono';
        phoneById[doc.id] = phone;

        String lName = '${lData['firstName'] ?? ''} ${lData['lastName'] ?? ''}'.trim();
        if (lName.isEmpty) lName = lData['fullName'] ?? lData['name'] ?? '';
        if (lName.isNotEmpty) phoneByName[lName.toLowerCase()] = phone;
      }

      final cellsSnap = await FirebaseFirestore.instance.collection('cells').where('churchId', isEqualTo: churchId).get();
      final allMembersSnap = await FirebaseFirestore.instance.collection('members').where('churchId', isEqualTo: churchId).get();

      Map<String, int> membersCountByCell = {};
      for (var mDoc in allMembersSnap.docs) {
        final mData = mDoc.data();
        
        String idParaContar = '';
        dynamic celdaRaw = mData['cellId'] ?? mData['assignedCellId'] ?? mData['cell'] ?? mData['celula'] ?? mData['cell_id'] ?? mData['assignedCell'];
        
        if (celdaRaw != null) {
          if (celdaRaw is String) idParaContar = celdaRaw.trim();
          else if (celdaRaw is DocumentReference) idParaContar = celdaRaw.id.trim();
        }
        
        if (idParaContar.isNotEmpty && idParaContar.length > 3) {
          membersCountByCell[idParaContar] = (membersCountByCell[idParaContar] ?? 0) + 1;
        }
      }

      List<Map<String, dynamic>> allCells = [];
      for (var doc in cellsSnap.docs) {
        final data = doc.data();
        int totalCount = membersCountByCell[doc.id] ?? 0;
        
        String nombreLider = data['leaderName'] ?? data['name'] ?? 'Sin líder';
        String telefonoLider = 'Sin teléfono';

        String? leaderId = data['leaderId'] ?? data['leaderUid'] ?? data['encargadoId'];
        if (leaderId != null && phoneById.containsKey(leaderId)) {
          telefonoLider = phoneById[leaderId]!;
        } else {
          String busquedaNombre = nombreLider.toLowerCase().trim();
          if (phoneByName.containsKey(busquedaNombre)) {
            telefonoLider = phoneByName[busquedaNombre]!;
          } else {
             for (var entry in phoneByName.entries) {
               if (entry.key.contains(busquedaNombre) || busquedaNombre.contains(entry.key)) {
                 telefonoLider = entry.value;
                 break;
               }
             }
          }
        }

        allCells.add({
          'Cód': data['code'] ?? 'N/A',
          'Líder': nombreLider,
          'Teléfono': telefonoLider,
          'Miembros': totalCount, 
          'count': totalCount,
        });
      }

      allCells.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      _topCells = allCells.take(5).toList();
      _riskCells = allCells.where((c) => (c['count'] as int) < 3).toList();

    } catch (e) { 
      debugPrint("Error en Células: $e"); 
    }

    if (mounted) {
      setState(() {
        _totalIglesia = tTotalIglesia;
        _totalMiembros = tMiembrosEnCelula; 
        _totalLideres = tLideres;
        _totalVoluntarios = tVoluntarios;
        _bautismosRealizados = tBautismos;
        _lideresBloqueados = tBloqueados;
        _nuevosCreyentesMes = tNuevosCreyentesMes;
        _nuevosEnCelulaMes = tNuevosEnCelulaMes;
        _blockedLeadersDetails = tBlockedLeadersDetails;
        _newBelieversDetails = tNewBelieversDetails;
        _newInCellDetails = tNewInCellDetails;
        _volunteersDetails = tVolunteersDetails;
        _chartSpots = tChartSpots;
        _chartMonths = tChartMonths;
        _isLoading = false;
      });
    }
  }

  String _getMonthName(int month) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return months[month - 1];
  }

  String _getShortMonthName(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }

  Future<void> _generarPDF() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Reporte Mensual - ${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text('Manantial de Bendiciones Central', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    pw.Divider(),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // 👇 CAMBIO APLICADO AQUÍ: WRAP CON LAS 6 TARJETAS 👇
              pw.Wrap(
                spacing: 15,
                runSpacing: 15,
                alignment: pw.WrapAlignment.spaceBetween,
                children: [
                  _pdfMetricBox('Total Iglesia', '$_totalIglesia'),
                  _pdfMetricBox('Nuevos Creyentes', '$_nuevosCreyentesMes'),
                  _pdfMetricBox('Nuevos en Célula', '$_nuevosEnCelulaMes'),
                  _pdfMetricBox('Voluntarios', '$_totalVoluntarios'),
                  _pdfMetricBox('Bautismos', '$_bautismosRealizados'),
                  _pdfMetricBox('Líderes Bloqueados', '$_lideresBloqueados'),
                ],
              ),
              
              pw.SizedBox(height: 30),
              pw.Text('Top 5 Células', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _pdfBuildTable(['Cód', 'Líder', 'Teléfono', 'Miembros'], _topCells),
              pw.SizedBox(height: 30),
              pw.Text('Células en Riesgo', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _pdfBuildTable(['Cód', 'Líder', 'Teléfono', 'Miembros'], _riskCells),
            ];
          },
        ),
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Reporte_Mensual_${_getMonthName(_selectedMonth.month)}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  pw.Widget _pdfMetricBox(String title, String value) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 4),
          pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  pw.Widget _pdfBuildTable(List<String> headers, List<Map<String, dynamic>> data) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data.map((row) => headers.map((h) => '${row[h] ?? ''}').toList()).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.all(8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2558),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reporte Mensual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateTime>(
                value: _selectedMonth,
                icon: const Icon(Icons.calendar_month, color: Color(0xFF0A2558), size: 18),
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
                items: List.generate(12, (index) {
                  final date = DateTime(DateTime.now().year, index + 1, 1);
                  return DropdownMenuItem(value: date, child: Text(_getMonthName(date.month)));
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMonth = value);
                    _loadReportData();
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isGeneratingPdf
                ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    tooltip: 'Descargar PDF',
                    onPressed: _generarPDF,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFF0A2558))))
            else ...[
              // 1. TARJETAS
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildMetricCard(
                    title: 'Total Iglesia',
                    subtitle: '$_totalMiembros miem. + $_totalLideres líderes',
                    value: '$_totalIglesia',
                    icon: Icons.groups,
                    bgColor: const Color(0xFFE0F2FE), 
                    iconColor: const Color(0xFF0284C7), 
                    textColor: const Color(0xFF0C4A6E),
                  ),
                  _buildMetricCard(
                    title: 'Nuevos Creyentes',
                    subtitle: 'Aún no están en célula',
                    value: '$_nuevosCreyentesMes',
                    icon: Icons.person_add_alt_1,
                    bgColor: const Color(0xFFDCFCE7), 
                    iconColor: const Color(0xFF16A34A), 
                    textColor: const Color(0xFF14532D),
                    onTap: () {
                      if (_newBelieversDetails.isEmpty) return;
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => _DetalleTablaScreen(
                          titulo: 'Nuevos Creyentes (Sin Célula)',
                          datos: _newBelieversDetails,
                          headers: ['Nombre', 'Teléfono', 'Fecha Registro', 'En Célula'],
                          icon: Icons.person_add_alt_1,
                          color: const Color(0xFF16A34A),
                        ),
                      ));
                    },
                  ),
                  _buildMetricCard(
                    title: 'Nuevos en Célula',
                    subtitle: 'Logrados sumar este mes',
                    value: '$_nuevosEnCelulaMes',
                    icon: Icons.group_add,
                    bgColor: const Color(0xFFFFEDD5), 
                    iconColor: const Color(0xFFF97316), 
                    textColor: const Color(0xFF7C2D12),
                    onTap: () {
                      if (_newInCellDetails.isEmpty) return;
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => _DetalleTablaScreen(
                          titulo: 'Nuevos Creyentes en Célula (${_getMonthName(_selectedMonth.month)})',
                          datos: _newInCellDetails,
                          headers: ['Nombre', 'Teléfono', 'Fecha Registro', 'Célula'],
                          icon: Icons.group_add,
                          color: const Color(0xFFF97316),
                        ),
                      ));
                    },
                  ),
                  _buildMetricCard(
                    title: 'Voluntarios',
                    subtitle: 'Activos este mes',
                    value: '$_totalVoluntarios',
                    icon: Icons.volunteer_activism,
                    bgColor: const Color(0xFFF3E8FF), 
                    iconColor: const Color(0xFF9333EA), 
                    textColor: const Color(0xFF4C1D95),
                    onTap: () {
                      if (_volunteersDetails.isEmpty) return;
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => _DetalleTablaScreen(
                          titulo: 'Voluntarios (${_getMonthName(_selectedMonth.month)})',
                          datos: _volunteersDetails,
                          headers: ['Nombre', 'Teléfono', 'Fecha Registro'],
                          icon: Icons.volunteer_activism,
                          color: const Color(0xFF9333EA),
                        ),
                      ));
                    },
                  ),
                  _buildMetricCard(
                    title: 'Bautismos',
                    subtitle: 'Programados este mes',
                    value: '$_bautismosRealizados',
                    icon: Icons.water_drop,
                    bgColor: const Color(0xFFFEF3C7), 
                    iconColor: const Color(0xFFEA580C), 
                    textColor: const Color(0xFF7C2D12),
                  ),
                  _buildMetricCard(
                    title: 'Líderes Bloqueados',
                    subtitle: 'En este mes',
                    value: '$_lideresBloqueados',
                    icon: Icons.person_off,
                    bgColor: const Color(0xFFFFE4E6), 
                    iconColor: const Color(0xFFE11D48), 
                    textColor: const Color(0xFF881337),
                    onTap: () {
                      if (_blockedLeadersDetails.isEmpty) return;
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => _DetalleTablaScreen(
                          titulo: 'Líderes Bloqueados (${_getMonthName(_selectedMonth.month)})',
                          datos: _blockedLeadersDetails,
                          headers: ['Nombre', 'Teléfono', 'Fecha Bloqueo', 'Estado'],
                          icon: Icons.person_off,
                          color: const Color(0xFFE11D48),
                        ),
                      ));
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              // 2. GRÁFICA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tendencia de Nuevos Creyentes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Últimos 6 meses (Total general)',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < _chartMonths.length) {
                                    return Text(_chartMonths[value.toInt()], style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _chartSpots,
                              isCurved: true,
                              color: const Color(0xFF16A34A),
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 5,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                    strokeColor: const Color(0xFF16A34A),
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF16A34A).withOpacity(0.3),
                                    const Color(0xFF16A34A).withOpacity(0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 3. TABLAS CERRADAS
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTableSection(
                      title: 'Top 5 Células',
                      icon: Icons.emoji_events,
                      iconColor: const Color(0xFFF59E0B), 
                      headers: ['Cód', 'Líder', 'Teléfono', 'Miembros'],
                      data: _topCells,
                      mostrarDatos: false, 
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => _DetalleTablaScreen(
                            titulo: 'Top 5 Células (${_getMonthName(_selectedMonth.month)})',
                            datos: _topCells,
                            headers: ['Cód', 'Líder', 'Teléfono', 'Miembros'],
                            icon: Icons.emoji_events,
                            color: const Color(0xFFF59E0B),
                          ),
                        ));
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildTableSection(
                      title: 'Células en Riesgo',
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFEF4444), 
                      headers: ['Cód', 'Líder', 'Teléfono', 'Miembros'],
                      data: _riskCells,
                      mostrarDatos: false, 
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => _DetalleTablaScreen(
                            titulo: 'Células en Riesgo (${_getMonthName(_selectedMonth.month)})',
                            datos: _riskCells,
                            headers: ['Cód', 'Líder', 'Teléfono', 'Miembros'],
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFEF4444),
                          ),
                        ));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 200, 
          height: 210, 
          decoration: BoxDecoration(
            color: bgColor, 
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: bgColor.withOpacity(0.6), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  child: CustomPaint(size: const Size(double.infinity, 60), painter: _WavePainter(waveColor: iconColor.withOpacity(0.3))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(22), topRight: Radius.circular(22), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(4),
                        ),
                        boxShadow: [BoxShadow(color: iconColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const Spacer(),
                    Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: textColor, height: 1)),
                    const SizedBox(height: 6),
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Positioned(
                bottom: 18,
                right: 18,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: iconColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]),
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> headers,
    required List<Map<String, dynamic>> data,
    VoidCallback? onTap,
    Map<int, TableColumnWidth>? customColumns,
    bool mostrarDatos = true, 
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
              
              if (onTap != null)
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF0A2558)),
                  label: const Text('Ver más', style: TextStyle(color: Color(0xFF0A2558), fontWeight: FontWeight.bold, fontSize: 13)),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2558).withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
            ],
          ),
          
          if (mostrarDatos) ...[
            const SizedBox(height: 20),
            if (data.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No hay datos disponibles.', style: TextStyle(color: Colors.grey.shade500))),
              )
            else
              Table(
                columnWidths: customColumns ?? const { 0: FlexColumnWidth(1), 1: FlexColumnWidth(3), 2: FlexColumnWidth(2), 3: FlexColumnWidth(1) },
                children: [
                  TableRow(
                    children: headers.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(h, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)),
                    )).toList(),
                  ),
                  ...data.map((row) {
                    return TableRow(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                      children: [
                        for (var key in row.keys)
                          if (key != 'fechaRaw' && key != 'count') 
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text('${row[key]}', style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
                            ),
                      ],
                    );
                  }).toList(),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color waveColor;
  _WavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = waveColor..style = PaintingStyle.fill;
    var path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, size.height, size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DetalleTablaScreen extends StatelessWidget {
  final String titulo;
  final List<Map<String, dynamic>> datos;
  final List<String> headers;
  final IconData icon;
  final Color color;

  const _DetalleTablaScreen({
    required this.titulo,
    required this.datos,
    required this.headers,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2558),
        foregroundColor: Colors.white, 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titulo, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), 
                blurRadius: 15, 
                offset: const Offset(0, 5)
              )
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1), 
                      shape: BoxShape.circle
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      titulo, 
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.black87 
                      )
                    )
                  ),
                ],
              ),
              const SizedBox(height: 25),
              if (datos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No hay datos disponibles.', 
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16)
                    )
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Table(
                    columnWidths: headers.length == 3
                        ? const { 0: FlexColumnWidth(3), 1: FlexColumnWidth(2.5), 2: FlexColumnWidth(1.5) }
                        : const { 0: FlexColumnWidth(1), 1: FlexColumnWidth(3), 2: FlexColumnWidth(2), 3: FlexColumnWidth(1) },
                    border: TableBorder.all(color: Colors.grey.shade200),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade100),
                        children: headers.map((h) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          child: Text(
                            h, 
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 13, 
                              color: Color(0xFF1E293B) 
                            )
                          ),
                        )).toList(),
                      ),
                      ...datos.map((row) {
                        List<Widget> cells = [];
                        for (var header in headers) {
                          cells.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              child: Text(
                                '${row[header] ?? ''}', 
                                style: const TextStyle(
                                  fontSize: 14, 
                                  color: Color(0xFF334155), 
                                  fontWeight: FontWeight.w500
                                )
                              ),
                            ),
                          );
                        }
                        return TableRow(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: Colors.grey.shade100))
                          ),
                          children: cells,
                        );
                      }).toList(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}