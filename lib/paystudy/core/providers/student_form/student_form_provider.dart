import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'student_form_notifier.dart';
import 'student_form_state.dart';


final studentFormProvider =
StateNotifierProvider<StudentFormNotifier, StudentFormState>(
      (ref) => StudentFormNotifier(),
);
