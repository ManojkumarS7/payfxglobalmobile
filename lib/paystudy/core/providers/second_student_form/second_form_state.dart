class SecondFormState {
  final bool hasOfferLetter;
  final String? appliedDetail;
  final bool? targetCourse;
  final bool? targetCountry;
  final bool showOtpPopup;

  const SecondFormState({
    this.hasOfferLetter = true,
    this.appliedDetail,
    this.targetCourse,
    this.targetCountry,
    this.showOtpPopup = false,
  });

  SecondFormState copyWith({
    bool? hasOfferLetter,
    String? appliedDetail,
    bool? targetCourse,
    bool? targetCountry,
    bool? showOtpPopup,
    bool clearAppliedDetail = false,
    bool clearTargetCourse = false,
    bool clearTargetCountry = false,
  }) {
    return SecondFormState(
      hasOfferLetter: hasOfferLetter ?? this.hasOfferLetter,
      appliedDetail: clearAppliedDetail ? null : (appliedDetail ?? this.appliedDetail),
      targetCourse: clearTargetCourse ? null : (targetCourse ?? this.targetCourse),
      targetCountry: clearTargetCountry ? null : (targetCountry ?? this.targetCountry),
      showOtpPopup: showOtpPopup ?? this.showOtpPopup,
    );
  }
}