import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../auth/models/user_profile.dart'; 

// 👇 IMPORTAMOS EL SERVICIO DEL CELULAR Y LÍDERES 👇
import '../home/services/home_dashboard_service.dart';
import 'leaders/services/leader_service.dart'; 
import 'leaders/screens/leader_assigned_members_screen.dart'; 

// 👇 IMPORTAMOS LOS SERVICIOS DE NOTIFICACIONES 👇
import '../notifications/services/admin_notification_service.dart';
import '../notifications/services/leader_notification_service.dart';

// 👇 IMPORTAMOS TODAS LAS PANTALLAS 👇
import '../auth/screens/account_hub_screen.dart'; 
import '../notifications/screens/admin_notifications_screen.dart'; 
import '../notifications/screens/leader_notifications_screen.dart'; 
import 'members/screens/members_list_screen.dart'; 
import 'leaders/screens/leaders_list_screen.dart'; 
import 'cells/screens/cells_list_screen.dart'; 
import 'members/models/members_list_filter.dart'; 

// 👇 IMPORTAMOS LA PANTALLA DE CUMPLEAÑOS 👇
import 'dashboard/screens/birthdays_screen.dart'; 

// Pantallas para la ventana "Más" y paneles
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
          // 1. MENÚ LATERAL AZUL
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
                        
                        // BOTÓN INICIO
                        _buildSidebarItem(icon: Icons.home, title: 'Inicio', index: 0, onTap: () => setState(() => _selectedIndex = 0)),
                        
                        // 👇 SOLO ADMIN 👇
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

          // 2. CONTENIDO PRINCIPAL
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

  // ==========================================
  // DASHBOARD DINÁMICO (MANTENIDO CLARO)
  // ==========================================
  Widget _buildDashboardInicio() {
    final p = widget.session.permissions;
    final isAdmin = p.isAdmin;
    final isSupervisor = p.canViewMySupervisedLeaders;

    if (isAdmin) {
      // 1. ADMINISTRADOR (5 TARJETAS)
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
      // 2. SUPERVISOR (3 TARJETAS)
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
      // 3. LÍDER (2 TARJETAS)
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
                Row(
                  children: [
                    const Text('👋 ', style: TextStyle(fontSize: 20)),
                    Expanded(child: Text('Bienvenido, ${widget.session.resolvedDisplayName ?? widget.session.email}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                  ],
                ),
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

// ==============================================================================
// PANEL DE OPCIONES DE CREYENTES (COLORES OSCUROS)
// ==============================================================================
class _CreyentesOptionsPanel extends StatelessWidget {
  final UserSession session;

  const _CreyentesOptionsPanel({required this.session});

  @override
  Widget build(BuildContext context) {
    final p = session.permissions;
    return Scaffold(
      backgroundColor: const Color(0xFF041E42), // Fondo oscuro
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

// ==============================================================================
// PANEL DE OPCIONES DE LÍDERES (COLORES OSCUROS)
// ==============================================================================
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

// ==============================================================================
// PANEL DE OPCIONES DE CÉLULAS (COLORES OSCUROS)
// ==============================================================================
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

// ==============================================================================
// PANTALLA COMPLETA CON TÍTULOS DE COLORES (MENÚ MÁS DINÁMICO - OSCURO)
// ==============================================================================
class _FullScreenMoreMenu extends StatelessWidget {
  final UserSession session;

  const _FullScreenMoreMenu({required this.session});

  @override
  Widget build(BuildContext context) {
    final isAdmin = session.permissions.isAdmin;
    final isSupervisor = session.permissions.canViewMySupervisedLeaders;

    return Scaffold(
      backgroundColor: const Color(0xFF041E42), // Fondo oscuro
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

  // 👇 ADMINISTRADOR (CON EL BOTÓN DE CUMPLEAÑOS) 👇
  Widget _buildAdminMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUMNA 1: BAUTISMO
          Expanded(flex: 1, child: _buildColumn(title: 'BAUTISMO', children: [
            
            // 👇 AQUI ESTA EL BOTÓN DE CUMPLEAÑOS 👇
            _buildVerticalItem(
              context, 
              icon: Icons.cake, 
              title: 'Cumpleaños', 
              description: 'Cumpleaños del día', 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BirthdaysScreen(session: session)))
            ),
            
            // LOS BOTONES ANTERIORES
            _buildVerticalItem(context, icon: Icons.calendar_month, title: 'Calendario', description: 'Programación fechas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BaptismCalendarScreen(registeredBy: session.uid, churchId: session.profile.churchId, actingLeaderId: session.profile.leaderId, permissions: session.permissions)))),
            _buildVerticalItem(context, icon: Icons.bar_chart, title: 'Estadísticas', description: 'Reporte bautizados', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BaptismDashboardScreen(session: session)))),
          ])),
          const SizedBox(width: 20),

          // COLUMNA 2: ADMINISTRACIÓN
          Expanded(flex: 1, child: _buildColumn(title: 'ADMINISTRACIÓN', children: [
            _buildVerticalItem(context, icon: Icons.volunteer_activism, title: 'Ofrendas', description: 'Gestión finanzas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OfferingDashboardScreen(session: session)))),
            _buildVerticalItem(context, icon: Icons.dashboard, title: 'Visitas', description: 'Métricas de visitas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VisitsDashboardScreen(session: session)))),
            _buildVerticalItem(context, icon: Icons.favorite_border, title: 'Pastoral', description: 'Métricas generales', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PastoralDashboardScreen(session: session)))),
          ])),
        ],
      ),
    );
  }

  // 👇 SUPERVISOR (SIN EL BOTÓN DE CUMPLEAÑOS) 👇
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

  // 👇 LÍDER (SIN EL BOTÓN DE CUMPLEAÑOS) 👇
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