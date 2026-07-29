import 'package:payfxglobal/paystudy/model/LoanSubmitModel/loan_applicationdata.dart';

class StudentFormState {
  final String gender;
  final bool isWhatsappNumber;
  final String? backlog;
  final List<String> selectedTests;
  final LoanApplicationdata formData;
  final bool isSubmitting;

  StudentFormState({
    this.gender = 'Male',
    this.isWhatsappNumber = true,
    this.backlog,
    List<String>? selectedTests,
    LoanApplicationdata? formData,
    this.isSubmitting = false,
  })  : selectedTests = selectedTests ?? [],
        formData = formData ?? LoanApplicationdata();

  StudentFormState copyWith({
    String? gender,
    bool? isWhatsappNumber,
    String? backlog,
    List<String>? selectedTests,
    LoanApplicationdata? formData,
    bool? isSubmitting,
  }) {
    return StudentFormState(
      gender: gender ?? this.gender,
      isWhatsappNumber: isWhatsappNumber ?? this.isWhatsappNumber,
      backlog: backlog ?? this.backlog,
      selectedTests: selectedTests ?? this.selectedTests,
      formData: formData ?? this.formData,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}


