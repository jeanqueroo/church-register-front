import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fila estilo lista de chats de WhatsApp.
class WhatsappListTile extends StatelessWidget {
  const WhatsappListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.showDivider = true,
    this.highlighted = false,
    this.subtitleMaxLines = 1,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final bool highlighted;
  final int subtitleMaxLines;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: palette.surface,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: palette.primary.withValues(alpha: 0.12),
                    child: Icon(icon, color: palette.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: highlighted
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: palette.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: subtitleMaxLines,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 0,
            color: palette.divider,
          ),
      ],
    );
  }
}
