

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:payfxglobal/paystudy/core/constants/app_dropfield.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
// import 'package:payfxglobal/paystudy/core/constants/app_textfield.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/paystudy/features/formpage/coApplicantform.dart';
import 'package:payfxglobal/paystudy/model/LoanSubmitModel/loan_applicationdata.dart';
import 'package:payfxglobal/paystudy/core/providers/university_form/university_form_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UniversityFormPage extends ConsumerStatefulWidget {
  final LoanApplicationdata formData;
  const UniversityFormPage({super.key, required this.formData});

  @override
  ConsumerState<UniversityFormPage> createState() => _UniversityFormPageState();
}

class _UniversityFormPageState extends ConsumerState<UniversityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  // --- Controllers ---
  final _universitynameController = TextEditingController();
  final _coursenameController = TextEditingController();
  final _courseDurationController = TextEditingController();
  final _loanAmountController = TextEditingController();

  // --- Focus nodes ---
  // FIX: All focus nodes declared, wired, and disposed
  final _universityFocus = FocusNode();
  final _courseNameFocus = FocusNode();
  final _courseDurationFocus = FocusNode();
  final _loanAmountFocus = FocusNode();

  // FIX: Dropdowns use Focus wrappers — one focus node each
  final _yearFocus = FocusNode();
  final _monthFocus = FocusNode();
  final _courseFocus = FocusNode();     // targeted course degree dropdown
  final _levelFocus = FocusNode();      // course level dropdown
  final _tenureFocus = FocusNode();     // tenure period dropdown
  final _mediaFocus = FocusNode();      // heard about us dropdown

  String? _selectedCourseId;

  // FIX: Track form readiness for button enable/disable
  bool _isFormReady = false;

  final Map<String, String> courseLevelMap = {
    'Master': '1',
    'Undergrad': '2',
    'UG in Diploma': '3',
    'PG in Diploma': '4',
    'Phd': '5',
  };

  List<String> _getYearOptions() {
    final currentYear = DateTime.now().year;
    return [currentYear.toString(), (currentYear + 1).toString()];
  }

  List<String> _getMonthOptions(String? selectedYear) {
    final allMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    if (selectedYear == DateTime.now().year.toString()) {
      return allMonths.sublist(DateTime.now().month - 1);
    }
    return allMonths;
  }

  List<String> targetedCourse() => [
    'Engineering / Technology', 'Management (MBA)', 'Analytics',
    'Masters in Engineering Management', 'Finance', 'Medical / MBBS',
    'Information Systems', 'Healthcare Management', 'Humanities',
    'Masters in Management', 'Law', 'Pure Sciences',
    'Human Resources/ HR', 'Project Management', 'Marketing',
    'Food/ Nutrition', 'Commercial Pilot Training', 'Design',
    'Supply Chain Management', 'Psychology', 'Education',
    'Hospitality / Tourism', 'Architecture/ Urban Development',
    'Environmental science/ management', 'Agriculture',
    'Animation / Graphics', 'Public Policy', 'Sports Management',
    'Fashion', 'Others',
  ];

  List<String> selectedmedia() => [
    'Google Search', 'Referral from a friend', 'Instagram', 'Facebook',
    'YouTube', 'Quora', 'Admission consultant', 'Senior/colleague',
    'Family', 'Session or ad in college campus', 'Linkedin',
    'Gmat Club', 'Other',
  ];

  @override
  void initState() {
    super.initState();

    // FIX: Listen to text controllers to recompute button state
    for (final c in [
      _universitynameController,
      _coursenameController,
      _courseDurationController,
      _loanAmountController,
    ]) {
      c.addListener(_updateFormReady);
    }
  }

  /// FIX: Centralized form readiness check.
  /// All required fields + provider-driven dropdowns must be non-null.
  void _updateFormReady() {
    final state = ref.read(universityFormProvider);
    final amount = int.tryParse(_loanAmountController.text);
    final ready = state.year != null &&
        state.month != null &&
        state.course != null &&
        state.countryId != null &&
        _universitynameController.text.trim().isNotEmpty &&
        _coursenameController.text.trim().isNotEmpty &&
        state.courseLevel != null &&
        _courseDurationController.text.trim().isNotEmpty &&
        amount != null &&
        amount >= 700000 &&
        amount <= 20000000 &&
        state.tenure != null &&
        state.media != null;

    if (mounted && ready != _isFormReady) {
      setState(() => _isFormReady = ready);
    }
  }

  @override
  void dispose() {
    // Controllers
    _universitynameController.dispose();
    _coursenameController.dispose();
    _courseDurationController.dispose();
    _loanAmountController.dispose();

    // FIX: Dispose ALL focus nodes — previously none existed / none were disposed
    _universityFocus.dispose();
    _courseNameFocus.dispose();
    _courseDurationFocus.dispose();
    _loanAmountFocus.dispose();
    _yearFocus.dispose();
    _monthFocus.dispose();
    _courseFocus.dispose();
    _levelFocus.dispose();
    _tenureFocus.dispose();
    _mediaFocus.dispose();

    super.dispose();
  }

  // Future<void> _submitForm() async {
  //   // FIX: Validate and auto-focus first failing field
  //   if (!_formKey.currentState!.validate()) {
  //     _focusFirstError();
  //     return;
  //   }
  //
  //   // FIX: Manually validate country since it has no FormField validator
  //   final state = ref.read(universityFormProvider);
  //   if (state.countryId == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please select a country')),
  //     );
  //     return;
  //   }
  //
  //   final notifier = ref.read(universityFormProvider.notifier);
  //
  //   widget.formData.course_start_year = state.year;
  //   widget.formData.course_start_month = state.month;
  //   widget.formData.course_degree = state.course;
  //   widget.formData.recipient_country_id = state.countryId;
  //   widget.formData.applied_university = _universitynameController.text;
  //   widget.formData.course_name = _coursenameController.text;
  //   widget.formData.course_level = courseLevelMap[state.courseLevel] ?? '';
  //   widget.formData.course_duration = _courseDurationController.text;
  //   widget.formData.loan_amount = _loanAmountController.text;
  //   widget.formData.tenure_period = state.tenure;
  //   widget.formData.hear_about = state.media;
  //   widget.formData.type = 'App';
  //   widget.formData.application_id = await _storage.read(key: 'applicant_id');
  //   widget.formData.exit_applicant_id = await _storage.read(key: 'applicant_id');
  //
  //   final success = await notifier.submit(
  //     widget.formData,
  //     widget.formData.toApiBody().cast<String, String>(),
  //   );
  //
  //   if (success && mounted) {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (_) => CoApplicantFormPage()),
  //     );
  //   }
  // }

  // In university_form_page.dart — replace the _submitForm method with this.
  // The only change is removing .cast<String, String>() from the submit() call.
  // toApiBody() returns Map<String, dynamic> and submit() now accepts that directly.

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _focusFirstError();
      return;
    }

    final state = ref.read(universityFormProvider);
    if (state.countryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a country')),
      );
      return;
    }

    final notifier = ref.read(universityFormProvider.notifier);

    widget.formData.course_start_year = state.year;
    widget.formData.course_start_month = state.month;
    widget.formData.course_degree = state.course;
    widget.formData.recipient_country_id = state.countryId;
    widget.formData.applied_university = _universitynameController.text;
    widget.formData.course_name = _coursenameController.text;
    widget.formData.course_level = courseLevelMap[state.courseLevel] ?? '';
    widget.formData.course_duration = _courseDurationController.text;
    widget.formData.loan_amount = _loanAmountController.text;
    widget.formData.tenure_period = state.tenure;
    widget.formData.hear_about = state.media;
    widget.formData.type = 'App';
    widget.formData.application_id = await _storage.read(key: 'applicant_id');
    widget.formData.exit_applicant_id = await _storage.read(key: 'applicant_id');

    // FIX: Was .cast<String, String>() — that throws at runtime because
    // toApiBody() contains int values (e.g. fxglb_user_id).
    // submit() now accepts Map<String, dynamic>, so pass the body directly.
    final success = await notifier.submit(
      widget.formData,
      widget.formData.toApiBody(), // <-- removed .cast<String, String>()
    );

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CoApplicantFormPage()),
      );
    }
  }

  void _focusFirstError() {
    final state = ref.read(universityFormProvider);

    if (state.year == null) {
      FocusScope.of(context).requestFocus(_yearFocus);
    } else if (state.month == null) {
      FocusScope.of(context).requestFocus(_monthFocus);
    } else if (state.course == null) {
      FocusScope.of(context).requestFocus(_courseFocus);
    } else if (state.countryId == null) {
      // Country is a GestureDetector — just scroll; no focusable node
    } else if (_universitynameController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_universityFocus);
    } else if (_coursenameController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_courseNameFocus);
    } else if (state.courseLevel == null) {
      FocusScope.of(context).requestFocus(_levelFocus);
    } else if (_courseDurationController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_courseDurationFocus);
    } else if (_loanAmountController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_loanAmountFocus);
    } else if (state.tenure == null) {
      FocusScope.of(context).requestFocus(_tenureFocus);
    } else if (state.media == null) {
      FocusScope.of(context).requestFocus(_mediaFocus);
    }
  }

  void _showCountryBottomSheet(
      BuildContext context,
      List<Map<String, String>> countries,
      ) {
    List<Map<String, String>> filteredCountries = List.from(countries);
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Country',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setSheetState(() {
                        filteredCountries = countries
                            .where((c) => c['name']!
                            .toLowerCase()
                            .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search country',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: AppColors.PrimaryColor),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ListView.builder(
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      return ListTile(
                        title: Text(
                          country['name']!,
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          _universitynameController.clear();
                          _coursenameController.clear();
                          _selectedCourseId = null;

                          ref
                              .read(universityFormProvider.notifier)
                              .selectCountry(
                            country['name']!,
                            country['id']!,
                          );

                          // FIX: Re-evaluate readiness after country selection
                          _updateFormReady();
                          Navigator.pop(context);
                          // Advance focus to university field after country pick
                          FocusScope.of(context)
                              .requestFocus(_universityFocus);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionList(
      List<String> suggestions, Function(String) onTap) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(suggestions[index]),
          onTap: () => onTap(suggestions[index]),
        ),
      ),
    );
  }

  Widget _buildCourseSuggestionList(
      List<Map<String, String>> suggestions,
      Function(Map<String, String>) onTap) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(suggestions[index]['course']!),
          onTap: () => onTap(suggestions[index]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(universityFormProvider);
    final notifier = ref.read(universityFormProvider.notifier);

    // FIX: Re-evaluate readiness when provider state changes
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFormReady());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Check Eligibility',
          style: TextStyle(
            color: AppColors.TextColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'University Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w500,
                    color: AppColors.TextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Tentative Course Start Year
                // FIX: Wrapped in Focus; onChanged advances to month focus
                Focus(
                  focusNode: _yearFocus,
                  child: AppDropdownField(
                    labelText: 'Tentative Course Start Year',
                    hintText: 'Tentative Course Start Year',
                    value: state.year,
                    items: _getYearOptions(),
                    onChanged: (value) {
                      notifier.state = notifier.state.copyWith(
                        year: value,
                        month: null, // reset month when year changes
                      );
                      FocusScope.of(context).requestFocus(_monthFocus);
                      _updateFormReady();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Tentative Course Start Month
                Focus(
                  focusNode: _monthFocus,
                  child: AppDropdownField(
                    labelText: 'Tentative Course Start Month',
                    hintText: 'Tentative Course Start Month',
                    value: state.month,
                    items: _getMonthOptions(state.year),
                    onChanged: (value) {
                      notifier.state = notifier.state.copyWith(month: value);
                      FocusScope.of(context).requestFocus(_courseFocus);
                      _updateFormReady();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Target Course Degree
                Focus(
                  focusNode: _courseFocus,
                  child: AppDropdownField(
                    labelText: 'Target Course Degree',
                    hintText: 'Target Course Degree',
                    value: state.course,
                    items: targetedCourse(),
                    onChanged: (value) {
                      notifier.state = notifier.state.copyWith(course: value);
                      // Country is next — it's a GestureDetector, no focus node,
                      // so we just unfocus and let the user tap it
                      FocusScope.of(context).unfocus();
                      _updateFormReady();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Country selector (custom GestureDetector — no AppDropdownField)
                // FIX: Added FormField wrapper for validation support
                FormField<String>(
                  validator: (_) {
                    if (state.countryId == null) {
                      return 'Please select a country';
                    }
                    return null;
                  },
                  builder: (fieldState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => _showCountryBottomSheet(
                                context, state.countries),
                            child: Container(
                              height: 60,
                              padding: const EdgeInsets.symmetric(horizontal: 16)
                                  .copyWith(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: fieldState.hasError
                                      ? Colors.red
                                      : state.country == null
                                      ? Colors.grey.shade400
                                      : AppColors.PrimaryColor,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    state.country ?? 'Select Country',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Satoshi',
                                      color: state.country == null
                                          ? Colors.grey[600]
                                          : AppColors.TextColor,
                                    ),
                                  ),
                                  Icon(Icons.keyboard_arrow_down,
                                      color: Colors.grey[600]),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            top: -6,
                            child: Container(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                              color: Colors.white,
                              child: Text(
                                'Country',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w500,
                                  color: fieldState.hasError
                                      ? Colors.red
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // FIX: Show validation error below country selector
                      if (fieldState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 6),
                          child: Text(
                            fieldState.errorText!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontFamily: 'Satoshi',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Target College / University
                // FIX: Added focusNode and onFieldSubmitted to advance focus
                AppTextField(
                  focusNode: _universityFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_courseNameFocus),
                  labelText: 'Target College/University',
                  controller: _universitynameController,
                  hintText: 'Target College/University',
                  enabled: state.countryId != null,
                  onChanged: (query) {
                    notifier.fetchColleges(query);
                  },
                ),

                if (state.showCollegeSuggestions &&
                    state.collegeSuggestions.isNotEmpty)
                  _buildSuggestionList(
                    state.collegeSuggestions,
                        (val) {
                      _universitynameController.text = val;
                      _coursenameController.clear();
                      _selectedCourseId = null;
                      notifier.state = notifier.state.copyWith(
                        showCollegeSuggestions: false,
                        courseLevel: null,
                        courseSuggestions: [],
                        showCourseSuggestions: false,
                      );
                      // Advance to course name after selecting a college
                      FocusScope.of(context).requestFocus(_courseNameFocus);
                      _updateFormReady();
                    },
                  ),
                const SizedBox(height: 16),

                // Target Course Name
                // FIX: focusNode added; onFieldSubmitted advances to course level
                // FIX: onChanged now correctly passes `query` (what user typed),
                //      not _universitynameController.text
                AppTextField(
                  focusNode: _courseNameFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_levelFocus),
                  controller: _coursenameController,
                  labelText: 'Target Course Name',
                  hintText: 'Target Course Name',
                  enabled: _universitynameController.text.isNotEmpty,
                  onChanged: (query) {
                    // FIX: Was passing university name as query — now passes the actual typed query
                    notifier.fetchCourses(query);
                  },
                ),

                if (state.showCourseSuggestions &&
                    state.courseSuggestions.isNotEmpty)
                  _buildCourseSuggestionList(
                    state.courseSuggestions,
                        (val) {
                      _coursenameController.text = val['course']!;
                      _selectedCourseId = val['id'];
                      notifier.state = notifier.state
                          .copyWith(showCourseSuggestions: false);
                      // Advance to course level after selecting a course
                      FocusScope.of(context).requestFocus(_levelFocus);
                      _updateFormReady();
                    },
                  ),
                const SizedBox(height: 16),

                // Target Course Level
                Focus(
                  focusNode: _levelFocus,
                  child: AppDropdownField(
                    labelText: 'Target Course Level',
                    hintText: 'Target Course Level',
                    value: state.courseLevel,
                    items: courseLevelMap.keys.toList(),
                    onChanged: (value) {
                      notifier.state =
                          notifier.state.copyWith(courseLevel: value);
                      FocusScope.of(context).requestFocus(_courseDurationFocus);
                      _updateFormReady();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Course Duration
                AppTextField(
                  focusNode: _courseDurationFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_loanAmountFocus),
                  labelText: 'Course Duration (IN MONTH)',
                  controller: _courseDurationController,
                  hintText: 'Course Duration (IN MONTH)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),


                Text('Minimum ₹7,00,000 & Maximum ₹2,00,00,000',style: TextStyle(color: Colors.grey,fontSize: 12),),

                const SizedBox(height: 12),

                // Required Loan Amount
                AppTextField(
                  focusNode: _loanAmountFocus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_tenureFocus);
                  },
                  labelText: 'Required Loan Amount INR',
                  controller: _loanAmountController,
                  hintText: 'Required Loan Amount INR',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final amount = int.tryParse(value ?? '');
                    if (amount == null) return 'Enter valid amount';
                    if (amount < 700000) return 'Minimum ₹7,00,000';
                    if (amount > 20000000) return 'Maximum ₹2,00,00,000';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tenure Period
                Focus(
                  focusNode: _tenureFocus,
                  child: AppDropdownField(
                    labelText: 'Tenure Period in Year',
                    hintText: 'Tenure Period in Year',
                    value: state.tenure,
                    items: ['5','6','7','8','9','10','11','12','13','14','15'],
                    onChanged: (value) {
                      notifier.state =
                          notifier.state.copyWith(tenure: value);
                      FocusScope.of(context).requestFocus(_mediaFocus);
                      _updateFormReady();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Heard About Us
                Focus(
                  focusNode: _mediaFocus,
                  child: AppDropdownField(
                    labelText: 'Where Did You Hear About Us?',
                    hintText: 'Where Did You Hear About Us?',
                    value: state.media,
                    items: selectedmedia(),
                    onChanged: (value) {
                      notifier.state =
                          notifier.state.copyWith(media: value);
                      FocusScope.of(context).unfocus();
                      _updateFormReady();
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // FIX: Button disabled until all required fields are valid
                // SizedBox(
                //   width: double.infinity,
                //   height: 56,
                //   child: ElevatedButton(
                //     onPressed: (state.loading || !_isFormReady)
                //         ? null
                //         : _submitForm,
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor:
                //       _isFormReady ? Colors.white : Colors.grey[200],
                //       foregroundColor: AppColors.PrimaryColor,
                //       elevation: 0,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(28),
                //         side: BorderSide(
                //           color: _isFormReady
                //               ? AppColors.PrimaryColor!
                //               : Colors.grey[400]!,
                //           width: 2,
                //         ),
                //       ),
                //     ),
                //     child: state.loading
                //         ? const LoadingOverlay()
                //         : Text(
                //       'Next',
                //       style: TextStyle(
                //         fontSize: 18,
                //         fontFamily: 'Satoshi',
                //         fontWeight: FontWeight.w500,
                //         color: _isFormReady
                //             ? AppColors.TextColor
                //             : Colors.grey[500],
                //       ),
                //     ),
                //   ),
                // ),

                AppPrimaryButton(title: 'Next',        onPressed: (state.loading || !_isFormReady)
            ? null
            : _submitForm),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}