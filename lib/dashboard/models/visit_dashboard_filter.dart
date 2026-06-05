class VisitDashboardFilter {
  const VisitDashboardFilter({
    this.churchId,
    this.leaderIds,
    this.scopeLabel,
  });

  /// Iglesia concreta; `null` = todas (solo superadmin).
  final String? churchId;

  /// Límita a estos líderes (supervisor).
  final Set<String>? leaderIds;

  /// Texto descriptivo del alcance visible en el dashboard.
  final String? scopeLabel;

  bool get restrictsLeaders =>
      leaderIds != null && leaderIds!.isNotEmpty;
}
