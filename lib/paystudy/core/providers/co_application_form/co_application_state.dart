class CoApplicantState {
  final String? employmentStatus;
  final String? relationship;
  final String? collateralType;
  final bool hasCollateral;
  final bool loading;
  final String? agentId;

  const CoApplicantState({
    this.employmentStatus,
    this.relationship,
    this.collateralType,
    this.hasCollateral = false,
    this.loading = false,
    this.agentId,
  });

  CoApplicantState copyWith({
    String? employmentStatus,
    String? relationship,
    String? collateralType,
    bool? hasCollateral,
    bool? loading,
    String? agentId,
  }) {
    return CoApplicantState(
      employmentStatus: employmentStatus ?? this.employmentStatus,
      relationship: relationship ?? this.relationship,
      collateralType: collateralType ?? this.collateralType,
      hasCollateral: hasCollateral ?? this.hasCollateral,
      loading: loading ?? this.loading,
      agentId: agentId ?? this.agentId,
    );
  }
}