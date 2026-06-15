import 'package:flutter/material.dart';

import '../locale/l10n_extensions.dart';
import '../theme/app_theme.dart';
import 'church_display_name.dart';

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

/// Scaffold con menú lateral estilo WhatsApp.
class SlideMenuScaffold extends StatefulWidget {
  const SlideMenuScaffold({
    super.key,
    this.churchId,
    this.titleFallback = appDisplayName,
    required this.body,
    required this.menuItems,
    required this.onSignOut,
    this.selectedMenuId,
    this.actions,
    this.floatingActionButton,
  });

  final String? churchId;
  final String titleFallback;
  final Widget body;
  final List<SlideMenuItem> menuItems;
  final VoidCallback onSignOut;
  final String? selectedMenuId;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  State<SlideMenuScaffold> createState() => _SlideMenuScaffoldState();
}

class _SlideMenuScaffoldState extends State<SlideMenuScaffold>
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
    final selectedId = widget.selectedMenuId;
    if (selectedId == null) return;
    for (final item in widget.menuItems) {
      if (item.children?.any((child) => child.id == selectedId) == true) {
        _expandedGroups.add(item.id);
      }
    }
  }

  String? _labelForMenuId(String id) {
    for (final item in widget.menuItems) {
      if (item.id == id) return item.label;
      for (final child in item.children ?? const <SlideMenuItem>[]) {
        if (child.id == id) return child.label;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  void _toggleGroup(SlideMenuItem item) {
    setState(() {
      if (_expandedGroups.contains(item.id)) {
        _expandedGroups.remove(item.id);
      } else {
        _expandedGroups.add(item.id);
      }
    });
  }

  Widget _buildMenuEntry(SlideMenuItem item, String selectedId) {
    if (item.isGroup) {
      final expanded = _expandedGroups.contains(item.id);
      final groupActive =
          item.children!.any((child) => child.id == selectedId);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrawerMenuTile(
            icon: item.icon,
            label: item.label,
            isActive: groupActive,
            trailing: Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: context.churchPalette.textSecondary,
            ),
            onTap: () => _toggleGroup(item),
          ),
          if (expanded)
            ...item.children!.map(
              (child) => Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _DrawerMenuTile(
                  icon: child.icon,
                  label: child.label,
                  isActive: child.id == selectedId,
                  dense: true,
                  onTap: () => _onItemTap(child),
                ),
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
    final headerLabel = _labelForMenuId(selectedId) ??
        (widget.menuItems.isNotEmpty ? widget.menuItems.first.label : '');

    final palette = context.churchPalette;

    return Scaffold(
      backgroundColor: palette.scaffoldBackground,
      floatingActionButton: widget.floatingActionButton,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WhatsappAppBar(
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
                color: palette.surface,
                child: SizedBox(
                  width: drawerWidth,
                  height: MediaQuery.sizeOf(context).height,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DrawerProfileHeader(
                        churchId: widget.churchId,
                        titleFallback: widget.titleFallback,
                        subtitle: headerLabel,
                        onClose: _closeMenu,
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
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

class _WhatsappAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _WhatsappAppBar({
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
                    fontSize: 20,
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
    required this.subtitle,
    required this.onClose,
  });

  final String? churchId;
  final String titleFallback;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return Container(
      color: palette.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        left: 8,
        right: 16,
        bottom: 20,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onClose,
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.church, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChurchDisplayName(
                  churchId: churchId,
                  fallback: titleFallback,
                  layout: ChurchDisplayNameLayout.drawer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
    this.trailing,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? iconColor;
  final Widget? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return Material(
      color: isActive ? palette.selectedTile : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: dense ? 10 : 14,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? palette.textSecondary,
                size: dense ? 22 : 24,
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: iconColor ?? palette.onSurface,
                    fontSize: dense ? 15 : 16,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
