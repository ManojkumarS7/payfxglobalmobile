class UniversityFormState {
  final String? year;
  final String? month;
  final String? course;
  final String? country;
  final String? countryId;
  final String? courseLevel;
  final String? tenure;
  final String? media;

  final List<Map<String, String>> countries;
  final List<String> collegeSuggestions;
  final List<Map<String, String>> courseSuggestions;

  final bool showCollegeSuggestions;
  final bool showCourseSuggestions;
  final bool loading;

  const UniversityFormState({
    this.year,
    this.month,
    this.course,
    this.country,
    this.countryId,
    this.courseLevel,
    this.tenure,
    this.media,
    this.countries = const [],
    this.collegeSuggestions = const [],
    this.courseSuggestions = const [],
    this.showCollegeSuggestions = false,
    this.showCourseSuggestions = false,
    this.loading = false,
  });

  UniversityFormState copyWith({
    String? year,
    String? month,
    String? course,
    String? country,
    String? countryId,
    String? courseLevel,
    String? tenure,
    String? media,
    List<Map<String, String>>? countries,
    List<String>? collegeSuggestions,
    List<Map<String, String>>? courseSuggestions,
    bool? showCollegeSuggestions,
    bool? showCourseSuggestions,
    bool? loading,
  }) {
    return UniversityFormState(
      year: year ?? this.year,
      month: month ?? this.month,
      course: course ?? this.course,
      country: country ?? this.country,
      countryId: countryId ?? this.countryId,
      courseLevel: courseLevel ?? this.courseLevel,
      tenure: tenure ?? this.tenure,
      media: media ?? this.media,
      countries: countries ?? this.countries,
      collegeSuggestions:
      collegeSuggestions ?? this.collegeSuggestions,
      courseSuggestions:
      courseSuggestions ?? this.courseSuggestions,
      showCollegeSuggestions:
      showCollegeSuggestions ?? this.showCollegeSuggestions,
      showCourseSuggestions:
      showCourseSuggestions ?? this.showCourseSuggestions,
      loading: loading ?? this.loading,
    );
  }
}
