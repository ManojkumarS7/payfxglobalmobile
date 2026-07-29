
import 'package:payfxglobal/paystudy/core/providers/second_student_form/second_form_state.dart';
import 'package:payfxglobal/paystudy/core/providers/second_student_form/second_form_notifier.dart';
import 'package:flutter_riverpod/legacy.dart';

final secondFormProvider =
StateNotifierProvider<SecondFormNotifier, SecondFormState>(
      (ref) => SecondFormNotifier(),
);

