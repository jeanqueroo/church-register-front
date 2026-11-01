import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../members/models/church_member.dart';
import '../../members/services/member_service.dart';

class SelectBaptismMembersScreen extends StatefulWidget {
  const SelectBaptismMembersScreen({
    super.key,
    required this.churchId,
    this.memberService,
    this.assignedLeaderId,
    this.initialSelectedIds = const {},
  });

  final String? churchId;
  final MemberService? memberService;
  final String? assignedLeaderId;
  final Set<String> initialSelectedIds;

  @override
  State<SelectBaptismMembersScreen> createState() =>
      _SelectBaptismMembersScreenState();
}

class _SelectBaptismMembersScreenState extends State<SelectBaptismMembersScreen> {
  final _searchController = TextEditingController();
  late Set<String> _selectedMemberIds;

  List<ChurchMember> _members = [];
  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _selectedMemberIds = Set<String>.from(widget.initialSelectedIds);
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final service = widget.memberService ?? MemberService();
      final members = await service.fetchMembersForBaptismAssignment(
        churchId: widget.churchId,
        assignedLeaderId: widget.assignedLeaderId,
        includeMemberIds: widget.initialSelectedIds,
      );
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  bool _matchesSearch(ChurchMember member, String query) {
    return member.matchesSearchQuery(query);
  }

  void _toggleMember(ChurchMember member, bool selected) {
    final id = member.id;
    if (id == null || id.isEmpty) return;

    setState(() {
      if (selected) {
        _selectedMemberIds.add(id);
      } else {
        _selectedMemberIds.remove(id);
      }
    });
  }

  void _confirmSelection() {
    final selected = _members
        .where(
          (member) =>
              member.id != null && _selectedMemberIds.contains(member.id),
        )
        .where(
          (member) =>
              member.canBeAssignedToBaptism ||
              widget.initialSelectedIds.contains(member.id),
        )
        .toList();
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = _members
        .where((member) => _matchesSearch(member, _searchController.text))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.baptismCalendarAssignMembersTitle),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _confirmSelection,
            child: Text(
              l10n.baptismCalendarAssignMembersConfirm(
                _selectedMemberIds.length,
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(l10n, filtered),
    );
  }

  Widget _buildBody(AppLocalizations l10n, List<ChurchMember> filtered) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.baptismCalendarAssignMembersLoadError,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadMembers,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.baptismCalendarAssignMembersSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.baptismCalendarAssignMembersHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.baptismCalendarAssignMembersEmpty,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final member = filtered[index];
                    final memberId = member.id;
                    if (memberId == null || memberId.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final isSelected = _selectedMemberIds.contains(memberId);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (checked) =>
                          _toggleMember(member, checked == true),
                      title: Text(member.fullName),
                      subtitle: member.phone.isNotEmpty
                          ? Text(member.phone)
                          : null,
                      secondary: CircleAvatar(
                        child: Text(
                          member.fullName.isNotEmpty
                              ? member.fullName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
