import 'package:flutter/material.dart';

import '../locale/l10n_extensions.dart';
import '../theme/app_theme.dart';
import 'church_display_name.dart';
import 'church_logo.dart';

class SlideMenuItem {
  SlideMenuItem({
    required this.id,
    required this.icon,
    required this.label,
    this.onTap,
    this.children,
  }) : assert(
          onTap != null || (children != null && children.isNotEmpty),
          'Un ítem de menú debe tener onTap o hijos',
        );

  final String id;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final List<SlideMenuItem>? children;

  bool get isGroup => children != null && children!.isNotEmpty;
}

/// Scaffold con menú lateral deslizable.
class SlideMenuScaffold extends StatefulWidget {
  const SlideMenuScaffold({
    super.key,
    this.churchId,
    this.titleFallback = appDisplayName,
    required this.body,
    required this.menuItems,
    required this.onSignOut,
    this.selectedMenuId,
    this.drawerRoleLabel,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final String? churchId;
  final String titleFallback;
  final Widget body;
  final List<SlideMenuItem> menuItems;
  final VoidCallback onSignOut;
  final String? selectedMenuId;
  final String? drawerRoleLabel;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  State<SlideMenuScaffold> createState() => SlideMenuScaffoldState();
}

class SlideMenuScaffoldState extends State<SlideMenuScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  final Set<String> _expandedGroups = {};

  bool get _isOpen => _controller.value > 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _syncExpandedGroups();
  }

  @override
  void didUpdateWidget(SlideMenuScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMenuId != widget.selectedMenuId ||
        oldWidget.menuItems != widget.menuItems) {
      _syncExpandedGroups();
    }
  }

  void _syncExpandedGroups() {
    _expandedGroups.clear();
    for (final item in widget.menuItems) {
      if (item.isGroup) {
        _expandedGroups.add(item.id);
      }
    }
    final selectedId = widget.selectedMenuId;
    if (selectedId == null) return;
    for (final item in widget.menuItems) {
      if (item.children?.any((child) => child.id == selectedId) == true) {
        _expandedGroups.add(item.id);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void openMenu() => _openMenu();

  void _closeMenu() => _controller.reverse();

  void _openMenu() => _controller.forward();

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _onItemTap(SlideMenuItem item) {
    final onTap = item.onTap;
    if (onTap == null) return;
    _closeMenu();
    onTap();
  }

  Widget _buildMenuEntry(SlideMenuItem item, String selectedId) {
    if (item.isGroup) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrawerSectionHeader(label: item.label),
          ...item.children!.map(
            (child) => _DrawerMenuTile(
              icon: child.icon,
              label: child.label,
              isActive: child.id == selectedId,
              dense: true,
              onTap: () => _onItemTap(child),
            ),
          ),
        ],
      );
    }

    return _DrawerMenuTile(
      icon: item.icon,
      label: item.label,
      isActive: item.id == selectedId,
      onTap: () => _onItemTap(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final drawerWidth = MediaQuery.sizeOf(context).width * 0.85;
    final selectedId =
        widget.selectedMenuId ?? widget.menuItems.firstOrNull?.id ?? 'home';
    final roleLabel = widget.drawerRoleLabel?.trim();

    final palette = context.churchPalette;

    return Scaffold(
      backgroundColor: palette.scaffoldBackground,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeAppBar(
                churchId: widget.churchId,
                titleFallback: widget.titleFallback,
                onMenuPressed: _toggleMenu,
                actions: widget.actions,
              ),
              Expanded(child: widget.body),
            ],
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_controller.value == 0) return const SizedBox.shrink();
              return FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _closeMenu,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4 * _controller.value),
                  ),
                ),
              );
            },
          ),
          SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Material(
                elevation: 8,
                color: palette.drawerBackground,
                child: SizedBox(
                  width: drawerWidth,
                  height: MediaQuery.sizeOf(context).height,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DrawerProfileHeader(
                        churchId: widget.churchId,
                        titleFallback: widget.titleFallback,
                        roleLabel: roleLabel,
                        onClose: _closeMenu,
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          children: [
                            ...widget.menuItems.map(
                              (item) => _buildMenuEntry(item, selectedId),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      _DrawerMenuTile(
                        icon: Icons.logout_rounded,
                        label: l10n.signOut,
                        iconColor: Colors.red.shade700,
                        labelColor: Colors.red.shade700,
                        onTap: () {
                          _closeMenu();
                          widget.onSignOut();
                        },
                      ),
                      SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar({
    required this.churchId,
    required this.titleFallback,
    required this.onMenuPressed,
    this.actions,
  });

  final String? churchId;
  final String titleFallback;
  final VoidCallback onMenuPressed;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.churchPalette;
    return Material(
      color: palette.primary,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: onMenuPressed,
                tooltip: l10n.menuTooltip,
              ),
              Expanded(
                child: ChurchDisplayName(
                  churchId: churchId,
                  fallback: titleFallback,
                  layout: ChurchDisplayNameLayout.appBar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerProfileHeader extends StatelessWidget {
  const _DrawerProfileHeader({
    required this.churchId,
    required this.titleFallback,
    required this.onClose,
    this.roleLabel,
  });

  final String? churchId;
  final String titleFallback;
  final String? roleLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return Container(
      color: palette.drawerBackground,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        left: 8,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: palette.onSurface),
            onPressed: onClose,
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: palette.primary.withValues(alpha: 0.1),
            child: ClipOval(
              child: ChurchLogo(size: 40, churchId: churchId),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChurchDisplayName(
                  churchId: churchId,
                  fallback: titleFallback,
                  layout: ChurchDisplayNameLayout.drawer,
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                if (roleLabel != null && roleLabel!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    roleLabel!,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: palette.primary.withValues(alpha: 0.08),
            child: Icon(Icons.person_rounded, color: palette.primary, size: 26),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  const _DrawerSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: palette.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          height: 1.3,
        ),
      ),
    );
  }
}

class _DrawerMenuTile extends StatelessWidget {
  const _DrawerMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.iconColor,
    this.labelColor,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? iconColor;
  final Color? labelColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    final activeColor = palette.primary.withValues(alpha: 0.1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: dense ? 10 : 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ??
                      (isActive ? palette.primary : palette.textSecondary),
                  size: dense ? 22 : 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: labelColor ??
                          (isActive ? palette.primary : palette.onSurface),
                      fontSize: dense ? 14 : 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
