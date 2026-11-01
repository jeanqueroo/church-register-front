import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/widgets/whatsapp_list_tile.dart';
import '../../l10n/app_localizations.dart';
import '../cell_member_capacity.dart';
import '../models/cell_over_capacity_entry.dart';
import '../services/cell_over_capacity_service.dart';
import 'split_cell_from_capacity_screen.dart';

class CellsOverCapacityScreen extends StatefulWidget {
  const CellsOverCapacityScreen({
    super.key,
    required this.registeredBy,
    this.churchId,
    this.permissions,
    this.overCapacityService,
  });

  final String registeredBy;
  final String? churchId;
  final AppPermissions? permissions;
  final CellOverCapacityService? overCapacityService;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<CellsOverCapacityScreen> createState() =>
      _CellsOverCapacityScreenState();
}

class _CellsOverCapacityScreenState extends State<CellsOverCapacityScreen> {
  late final CellOverCapacityService _overCapacityService;

  List<CellOverCapacityEntry> _entries = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _overCapacityService =
        widget.overCapacityService ?? CellOverCapacityService();
    _load();
  }

  Future<void> _load() async {
    final churchId = widget.churchId?.trim();
    if (churchId == null || churchId.isEmpty) {
      setState(() {
        _entries = [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final entries = await _overCapacityService.fetchForChurch(churchId);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = context.l10n.cellsOverCapacityLoadError;
        _loading = false;
      });
    }
  }

  Future<void> _openSplit(CellOverCapacityEntry entry) async {
    final cellId = entry.cell.id?.trim();
    if (cellId == null || cellId.isEmpty) return;

    final split = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SplitCellFromCapacityScreen(
          sourceCellId: cellId,
          registeredBy: widget.registeredBy,
          churchId: widget.churchId,
          permissions: widget._permissions,
        ),
      ),
    );

    if (split == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final churchId = widget.churchId?.trim();

    return RoleGate(
      permissions: widget._permissions,
      allowed: widget._permissions.canRegisterCell,
      deniedMessage: l10n.cellsOverCapacityDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.cellsOverCapacityTitle),
        ),
        body: churchId == null || churchId.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.cellsOverCapacityNoChurch,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: _buildBody(l10n),
              ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_loadError != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_entries.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.check_circle_outline,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.cellsOverCapacityEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.cellsOverCapacityEmptySubtitle(
                CellMemberCapacity.maxMembers,
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.cellsOverCapacityIntro(CellMemberCapacity.maxMembers),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._entries.map((entry) => _buildEntryTile(l10n, entry)),
      ],
    );
  }

  Widget _buildEntryTile(AppLocalizations l10n, CellOverCapacityEntry entry) {
    final cell = entry.cell;
    final cellLabel = cell.displayLabel;
    final leaderName = cell.leaderName?.trim();
    final subtitleParts = <String>[
      l10n.notificationCellCapacityBody(cellLabel, entry.memberCount),
      if (leaderName != null && leaderName.isNotEmpty)
        l10n.cellsOverCapacityLeaderLabel(leaderName),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: WhatsappListTile(
        icon: Icons.warning_amber_rounded,
        title: cellLabel,
        subtitle: subtitleParts.join('\n'),
        subtitleMaxLines: 3,
        showDivider: false,
        trailing: IconButton(
          icon: const Icon(Icons.call_split_outlined),
          tooltip: l10n.splitCellCreateAction,
          onPressed: () => _openSplit(entry),
        ),
        onTap: () => _openSplit(entry),
      ),
    );
  }
}
