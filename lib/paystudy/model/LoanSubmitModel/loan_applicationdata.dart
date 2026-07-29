class LoanApplicationdata {



  String? payfx_user_id;
  String? student_name;
  String? gender;
  String? phone;
  String? isWhatsappNumber;
  String? whatsapp_number;
  String? email;
  String? education_avilable;
  String? education_applied;
  String? decided_course;
  String? decided_country;

  String? course_start_year;
  String? course_start_month;
  String? course_level;
  String? course_degree;
  String? course_name;
  String? course_id;
  String? course_duration;
  String? loan_amount;
  String? recipient_country_id;
  String? applied_university;
  String? hear_about;
  String? tenure_period;
  String? backlogs;
  String? highest_degree;
  String? work_experince;
  String? monthly_income;
  String? test_taken;
  String? gre_verbal;
  String? gre_quant;
  String? gre_analytical_writing;
  String? gmat_score;
  String? ielts_score;
  String? toefl_score;
  String? pte_score;
  String? duolingo_score;
  String? utm_url;
  String? type;
  String? added_date;
  String? loan_date;

  String? co_applicant_name;
  String? relationship_type;
  String? co_applicant_employement_status;
  String? co_applicant_monthly_income;
  String? co_applicant_monthly_emi;
  String? co_applicant_pincode;
  String? co_applicant_phone;
  String? security_collateral;
  String? collateral_value;
  String? collateral_type;
  String? collateral_pincode;
  String? ref_agent_id;
  String? loan_trans_type;
  String? promo_code;
  String? application_id;
  String? exit_applicant_id;



  Map<String, dynamic> toApiBody() {
    final Map<String, dynamic> body = {

      'fxglb_user_id' : int.tryParse(payfx_user_id ?? '0') ?? 0,

      'applicant_name': student_name ?? '',
      'email': email ?? '',
      'phone': phone ?? '',
      'gender': gender ?? '',
      'whatsappAvailable': isWhatsappNumber ?? '',
      'whatsappNumber': whatsapp_number ?? '',

      'educationAvailable`': education_avilable ?? '',
      'educationapplied': education_applied ?? '',
      'decidedcourse': decided_course ?? '',
      'decidedcountry' : decided_country ?? '',

      'course_start_year': course_start_year ?? '',
      'course_start_month': course_start_month ?? '',
      'course_level': course_level ?? '',
      'course_degree': course_degree ?? '',
      'course_name': course_name ?? '',
      'course_id': course_id ?? '',
      'loan_amount': loan_amount ?? '',
      'recipient_country_id': recipient_country_id ?? '',
      'course_duration': course_duration ?? '',
      'applied_university': applied_university ?? '',
      'hear_about': hear_about ?? '',
      'tenure_period': tenure_period ?? '',
      'backlogs': backlogs ?? '',
      'highest_degree': highest_degree ?? '',
      'work_experince': work_experince ?? '',
      'monthly_income': monthly_income ?? '',

      'test_taken': test_taken ?? '',
      'gre_verbal': gre_verbal ?? '',
      'gre_quant': gre_quant ?? '',
      'gre_analytical_writing': gre_analytical_writing ?? '',
      'gmat_score': gmat_score ?? '',
      'ielts_score': ielts_score ?? '',
      'toefl_score': toefl_score ?? '',
      'pte_score': pte_score ?? '',
      'duolingo_score': duolingo_score ?? '',

      'utm_url': utm_url ?? '',
      'type': 'App',
      'added_date': added_date ?? '',
      'loan_date': loan_date ?? '',
      'co_applicant_name': co_applicant_name ?? '',
      'relation_co_applicant': relationship_type ?? '',
      'coapplicant_emp_status': co_applicant_employement_status ?? '',
      'coapplicant_monthly_income': co_applicant_monthly_income ?? '',
      'coapplicant_monthly_emi': co_applicant_monthly_emi ?? '',
      'coapplicant_pincode': co_applicant_pincode ?? '',
      'coapplicant_phone': co_applicant_phone ?? '',
      'collateral': security_collateral ?? 'No',
      'ref_agent_id': ref_agent_id ?? '',
      'loan_trans_type': loan_trans_type ?? '',
      'agent_code': promo_code ?? '',
      'applicant_id': application_id ?? '',
      'exit_applicant_id': application_id ?? ''

    };
    return body;
  }
}
