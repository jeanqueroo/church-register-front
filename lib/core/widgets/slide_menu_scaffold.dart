import 'package:flutter/material.dart';

import '../locale/l10n_extensions.dart';
import '../theme/app_theme.dart';
import 'church_display_name.dart';

class SlideMenuItem {
  const SlideMenuItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
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
    _closeMenu();
    item.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final drawerWidth = MediaQuery.sizeOf(context).width * 0.85;
    final selectedId =
        widget.selectedMenuId ?? widget.menuItems.firstOrNull?.id ?? 'home';
    final headerLabel = widget.menuItems
        .where((item) => item.id == selectedId)
        .map((item) => item.label)
        .firstOrNull ??
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
                              (item) => _DrawerMenuTile(
                                icon: item.icon,
                                label: item.label,
                                isActive: item.id == selectedId,
                                onTap: () => _onItemTap(item),
                              ),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return Material(
      color: isActive ? palette.selectedTile : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? palette.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: iconColor ?? palette.onSurface,
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
