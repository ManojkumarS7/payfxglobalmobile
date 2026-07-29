
import 'package:payfxglobal/paystudy/core/providers/co_application_form/co_application_state.dart';
import 'package:payfxglobal/paystudy/core/providers/co_application_form/co_application_notifier.dart';
import 'package:flutter_riverpod/legacy.dart';

final coApplicantProvider =
StateNotifierProvider<CoApplicantNotifier, CoApplicantState>(
      (ref) => CoApplicantNotifier(),
);