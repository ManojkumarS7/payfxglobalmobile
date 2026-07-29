import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:payfxglobal/paystudy/core/providers/student_form/student_form_state.dart';



class StudentFormNotifier extends StateNotifier<StudentFormState> {
  StudentFormNotifier() : super(StudentFormState ());

  void setGender(String gender) {
    state = state.copyWith(gender: gender);
  }

  void setWhatsapp(bool value) {
    state = state.copyWith(isWhatsappNumber: value);
  }

  void setBacklog(String? value) {
    state = state.copyWith(backlog: value);
  }

  void toggleTest(String test) {
    final tests = [...state.selectedTests];

    if (test == 'None') {
      state = state.copyWith(selectedTests: ['None']);
      return;
    }

    tests.remove('None');

    if (tests.contains(test)) {
      tests.remove(test);
    } else {
      tests.add(test);
    }

    state = state.copyWith(selectedTests: tests);
  }
}
