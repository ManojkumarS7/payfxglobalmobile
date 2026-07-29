import 'package:flutter_riverpod/legacy.dart';
import 'package:payfxglobal/paystudy/core/providers/university_form/university_form_state.dart';
import 'package:payfxglobal/paystudy/core/providers/university_form/university_form_notifier.dart';




final universityFormProvider =
StateNotifierProvider<UniversityFormNotifier, UniversityFormState>(
      (ref) => UniversityFormNotifier(),
);