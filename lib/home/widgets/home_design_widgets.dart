import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/church_logo.dart';

/// Color de acento para iconos de acciones rápidas.
Color homeQuickActionAccent(int index) => kPositiveActionColor;

class HomeWelcomeBanner extends StatelessWidget {
  const HomeWelcomeBanner({
    super.key,
    required this.welcomeText,
    required this.subtitle,
    this.churchId,
  });

  final String welcomeText;
  final String subtitle;
  final String? churchId;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: palette.primary.withValues(alpha: 0.1),
            child: ClipOval(
              child: ChurchLogo(size: 48, churchId: churchId),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  welcomeText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.primary,
                  ),
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailing!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: palette.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class HomeStatCardData {
  const HomeStatCardData({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.onTap,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;
}

class HomeStatCardsRow extends StatelessWidget {
  const HomeStatCardsRow({super.key, required this.cards});

  final List<HomeStatCardData> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _HomeStatCard(data: cards[index]),
      ),
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  const _HomeStatCard({required this.data});

  final HomeStatCardData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: Material(
        color: data.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: data.onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(data.icon, color: data.foregroundColor, size: 26),
                const Spacer(),
                Text(
                  data.value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: data.foregroundColor,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: data.foregroundColor,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: data.foregroundColor.withValues(alpha: 0.75),
                        height: 1.2,
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

class HomeQuickActionTile extends StatelessWidget {
  const HomeQuickActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accentColor,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accentColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: palette.primary,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: palette.textSecondary,
                                      height: 1.3,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: palette.textSecondary.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider) const SizedBox(height: 10),
      ],
    );
  }
}

enum HomeBottomNavItem {
  home,
  believers,
  leaders,
  cells,
  more,
}

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.current,
    required this.onSelected,
    required this.labels,
    this.visibleItems = const [
      HomeBottomNavItem.home,
      HomeBottomNavItem.believers,
      HomeBottomNavItem.leaders,
      HomeBottomNavItem.cells,
      HomeBottomNavItem.more,
    ],
  });

  final HomeBottomNavItem current;
  final ValueChanged<HomeBottomNavItem> onSelected;
  final Map<HomeBottomNavItem, String> labels;
  final List<HomeBottomNavItem> visibleItems;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final item in visibleItems)
                Expanded(
                  child: _HomeBottomNavButton(
                    icon: _iconFor(item),
                    label: labels[item] ?? '',
                    selected: current == item,
                    onTap: () => onSelected(item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(HomeBottomNavItem item) {
    return switch (item) {
      HomeBottomNavItem.home => Icons.home_rounded,
      HomeBottomNavItem.believers => Icons.people_rounded,
      HomeBottomNavItem.leaders => Icons.workspace_premium_rounded,
      HomeBottomNavItem.cells => Icons.home_work_rounded,
      HomeBottomNavItem.more => Icons.more_horiz_rounded,
    };
  }
}

class _HomeBottomNavButton extends StatelessWidget {
  const _HomeBottomNavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    final color = selected ? palette.primary : palette.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estilos predefinidos para tarjetas de resumen.
abstract final class HomeStatStyles {
  static const members = (
    bg: Color(0xFFE3F2FD),
    fg: Color(0xFF1565C0),
    icon: Icons.people_rounded,
  );
  static const newBelievers = (
    bg: Color(0xFFE8F5E9),
    fg: Color(0xFF2E7D32),
    icon: Icons.person_add_alt_1_rounded,
  );
  static const leaders = (
    bg: Color(0xFFF3E5F5),
    fg: Color(0xFF7B1FA2),
    icon: Icons.workspace_premium_rounded,
  );
  static const cells = (
    bg: Color(0xFFFFF3E0),
    fg: Color(0xFFE65100),
    icon: Icons.home_work_rounded,
  );
  static const baptisms = (
    bg: Color(0xFFE0F2F1),
    fg: Color(0xFF00695C),
    icon: Icons.water_drop_rounded,
  );
  static const disciples = (
    bg: Color(0xFFE8EAF6),
    fg: Color(0xFF3949AB),
    icon: Icons.groups_rounded,
  );
}
