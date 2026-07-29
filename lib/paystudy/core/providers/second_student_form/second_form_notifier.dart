
import 'package:flutter_riverpod/legacy.dart';
import 'package:payfxglobal/paystudy/core/providers/second_student_form/second_form_state.dart';


class SecondFormNotifier extends StateNotifier<SecondFormState> {
  SecondFormNotifier() : super(const SecondFormState());

  void toggleOfferLetter(bool value) {
    state = state.copyWith(
      hasOfferLetter: value,
      clearAppliedDetail: true,
      clearTargetCourse: true,
      clearTargetCountry: true,
    );
  }

  void setAppliedDetail(String value) {
    state = state.copyWith(
      appliedDetail: value,
      clearTargetCourse: true,
      clearTargetCountry: true,
    );
  }


  void setTargetCourse(bool value) {
    state = state.copyWith(
      targetCourse: value,
      clearTargetCountry: true,
    );
  }


  void setTargetCountry(bool value) {
    state = state.copyWith(targetCountry: value);
  }


  void showOtp(bool value) {
    state = state.copyWith(showOtpPopup: value);
  }
}