import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:payfxglobal/paystudy/features/application_process/application_process.dart';
import 'package:payfxglobal/paystudy/features/loanOption/loanOption_card.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payfxglobal/paystudy/core/services/local_storage_service.dart';
import 'package:payfxglobal/paystudy/core/network/api_service.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/paystudy/core/providers/bottomBar/bottom_nav_provider.dart';
import 'package:payfxglobal/paystudy/core/constants/dashboard.dart';
import 'package:payfxglobal/widgets/custom_button.dart';


class CountryDetail {
  final String country_name;

  CountryDetail({required this.country_name});

  factory CountryDetail.fromJson(Map<String, dynamic> json) {
    return CountryDetail(
      country_name: json['country_name']?.toString() ?? '',
    );
  }
}

class LoanOptionspage extends ConsumerStatefulWidget {
  const LoanOptionspage({super.key});

  @override
  ConsumerState<LoanOptionspage> createState() => _LoanOptionspageState();
}

class _LoanOptionspageState extends ConsumerState<LoanOptionspage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final LocalStorageService _localStorage = LocalStorageService();
  final ApiService _apiService = ApiService();

  List<dynamic> offers = [];
  bool isLoading = true;
  bool isSubmitting = false;
  bool isAccepted = false;
  CountryDetail? _countryDetail;

  @override
  void initState() {
    super.initState();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    setState(() => isLoading = true);

    try {
      final applicantId = await _storage.read(key: 'applicant_id') ?? '';

      final response = await _apiService.get(
        "home/v1/api/loan_eligible_details/$applicantId",
      );

      dynamic responseData = response.data;

      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      if (response.statusCode == 200 && responseData["status"] == true) {
        final List<dynamic> offerList =
            responseData["data"]["offers"] ?? [];

        final countryJson =
        responseData["data"]["countryDetails"];

        setState(() {
          offers = offerList;
          _countryDetail = countryJson != null
              ? CountryDetail.fromJson(countryJson)
              : null;
          isLoading = false;
        });
      } else {
        throw Exception(responseData["message"] ?? "Failed to fetch offers");
      }
    } catch (e) {
      debugPrint("Error fetching offers: $e");

      setState(() => isLoading = false);

      if (mounted) {
        AppSnackbar.show(context, 'Failed to fetch matching loan options', success: false);
      }
    }
  }

  Future<void> _submitSelectedOffers() async {

    var selectedOffers =
    offers.where((o) => o['is_selected'] == true).toList();

    if (selectedOffers.isEmpty) {
      AppSnackbar.show(context, 'Please select at least one offer', success: false);
      return;
    }

    if (isAccepted == false) {
      AppSnackbar.show(context, 'Please accept the terms and conditions', success: false);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final applicantIdStr =
          await _storage.read(key: 'applicant_id') ?? '';

      final int applicantId = int.tryParse(applicantIdStr) ?? 0;

      final List<Map<String, dynamic>> formattedOffers =
      selectedOffers.map((o) {
        return {
          "university_loan_course_id":
          int.tryParse(o['university_loan_course_id']?.toString() ?? '0') ?? 0,
          "bank_id":
          int.tryParse(o['bank_id']?.toString() ?? '0') ?? 0,
          "bank_category_id":
          int.tryParse(o['bank_category_id']?.toString() ?? '0') ?? 0,
          "secured_type": o['secured_type'] ?? "secured"
        };
      }).toList();

      final Map<String, dynamic> body = {
        "applicant_id": applicantId,
        "offers": formattedOffers
      };

      final response = await _apiService.post(
        "home/v1/api/submit_loan_offers",
        data: body,
      );

      debugPrint("RESPONSE DATA: ${response.data}");


      dynamic responseData = response.data;

      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      if (response.statusCode == 200 &&
          (responseData['status'] == true ||
              responseData['message'] ==
                  'Offers submitted successfully')) {

        final String? loanRefNo =
        responseData['data']?['loan_ref_no'];

        if (loanRefNo != null && loanRefNo.isNotEmpty) {
          await _localStorage.saveLoanNumber(loanRefNo);
        }

        final String? loanstatus =
        responseData['data']?['loan_status'];

        await _storage.write(
          key: 'loan_status',
          value: loanstatus,
        );


        if (mounted) {
          AppSnackbar.show(context, 'Offers submitted successfully!');
          



          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const ApplicationProcess()),
                (route) => false,
          );
        }
      } else {
        throw Exception(responseData['message'] ?? "Submission failed");
      }
    } catch (e) {
      debugPrint("Error submitting offers: $e");
      if (mounted) {
        AppSnackbar.show(context, 'Something went wrong', success: false);
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final countryname = _countryDetail?.country_name ?? '';

    List<double> sortedUniqueRates = offers
        .map((o) => double.tryParse(o['interest_rate']?.toString() ?? '0.0') ?? 0.0)
        .where((rate) => rate > 0)
        .toSet()
        .toList();
    sortedUniqueRates.sort();
    final leastTwoRates = sortedUniqueRates.take(2).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Matching Loan Options',
          style: TextStyle(
            color: AppColors.TextColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Satoshi',
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.PrimaryColor))
          : offers.isEmpty
              ? const Center(
                  child: Text(
                    'No matching loan options found.',
                    style: TextStyle(fontFamily: 'Satoshi', fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Congratulations !',
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w800,
                              color: AppColors.TextColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Great news — we’ve found the best options for your study abroad journey to the $countryname . Once you accept this option, our Loan Experts will connect with you to guide you through the process and may also suggest other top options that could be even more suitable.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w300,
                              color: AppColors.TextColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                'Best Loan Matching Options',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.TextColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SvgPicture.asset(
                                'assets/icons/gif.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.TextColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          ...offers.asMap().entries.map((entry) {
                            int index = entry.key;
                            var offer = entry.value;
                            
                            final currentRate = double.tryParse(offer['interest_rate']?.toString() ?? '0.0') ?? 0.0;
                            final isLeastTwo = leastTwoRates.contains(currentRate);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 30),
                              child: LoanOptionCard(
                                optionTitle: 'Option ${index + 1}',
                                isSelected: offer['is_selected'] == true,
                                isLeastTwo: isLeastTwo,
                                onTap: () {
                                  setState(() {
                                    offer['is_selected'] = !(offer['is_selected'] == true);
                                  });
                                },
                                loanAmount: offer['loan_amount']?.toString() ?? '0',
                                interestRate: offer['interest_rate']?.toString() ?? '0',
                                duringEmi: offer['during_course_emi']?.toString() ?? '0',
                                afterEmi: offer['after_course_emi']?.toString() ?? '0',
                                bank:  offer['bank_type']?.toString().toUpperCase() ?? '',
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _checkBox(),

                              const Text(
                                'I Accept the',
                                style: TextStyle(
                                  color: AppColors.TextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Satoshi',
                                ),
                              ),

                        TextButton(onPressed: (){

                          showDialog(
                            context: context,
                            barrierDismissible: false, // force user to tap Close
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: AppColors.TextColor,
                                  width: 1.5,
                                ),
                              ),



                              content: SizedBox(
                                width: double.maxFinite,
                                height: MediaQuery.of(context).size.height * 0.6, // 60% screen height
                                child: SingleChildScrollView(
                                  child: const Text(
                                    '''
Nature of this Document – This document is issued solely as an acknowledgment that the applicant has applied for an education loan through the PayStudy platform, operated by PayFX Fintech Solutions Private Limited (“PayFX”). It is an indicative offer generated on the basis of information provided by the applicant. It is not a sanction letter, commitment to lend, or a legally binding contract.

Role of PayStudy – PayStudy acts only as a loan facilitator. PayStudy does not itself provide, sanction, or disburse loans. All loans are processed and sanctioned solely by RBI-registered Banks and Non-Banking Financial Companies (NBFCs).

Indicative Loan Terms – The loan amount, interest rate, tenure, and other details shown are indicative and may be altered by the concerned Bank/NBFC at any time before formal sanction.

Verification & Documentation – Loan sanction is subject to submission of required documents, satisfactory credit checks and the lender’s internal policy.

No Guarantee of Loan – This confirmation does not guarantee loan sanction. Final decision rests with Bank/NBFC.

RBI Compliance – Lenders will process the loan in accordance with RBI guidelines.

Limitation of Liability – PayStudy/PayFX and affiliates are not liable for loan rejections, delays, or damages arising from reliance on this document.

Indemnity – Applicant agrees to indemnify PayStudy/PayFX for claims arising from false or incomplete information.

No Financial Advice – The document does not constitute financial, investment, legal, or tax advice.

Data Privacy – Applicant data will be shared only with partner Banks/NBFCs for processing the loan application.

Governing Law & Jurisdiction – This document is governed by the laws of India. Courts at Coimbatore, Tamil Nadu shall have exclusive jurisdiction.

By accepting this document, the applicant confirms they have read, understood and agreed to these terms and that the information provided is true and accurate.

PayStudy is a part of PayFX Fintech Solutions Private Limited | www.paystudy.in

This confirmation does not constitute a loan sanction and is issued only as proof of application through PayStudy.
''',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 14,
                                      height: 1.6,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.TextColor,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                              ),


                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text(
                                    'CLOSE',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.PrimaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );


                        }, child:Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: AppColors.TextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Satoshi',
                          ),
                        ),)

                            ],
                          ),

                          const SizedBox(height: 40),


                          AppPrimaryButton(title: 'SUBMIT SELECTED OFFERS',
                                onPressed: isSubmitting ? null : _submitSelectedOffers,
                          ),

                          // SizedBox(
                          //   width: double.infinity,
                          //   height: 56,
                          //   child: ElevatedButton(
                          //     onPressed: isSubmitting ? null : _submitSelectedOffers,
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Colors.white,
                          //       foregroundColor: AppColors.PrimaryColor,
                          //       elevation: 0,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(28),
                          //         side: const BorderSide(
                          //           color: AppColors.PrimaryColor,
                          //           width: 2,
                          //         ),
                          //       ),
                          //     ),
                          //     child: isSubmitting
                          //       ? const CircularProgressIndicator(color: AppColors.PrimaryColor)
                          //       : const Text(
                          //           'SUBMIT SELECTED OFFERS',
                          //           style: TextStyle(
                          //             fontSize: 18,
                          //             fontFamily: 'Satoshi',
                          //             fontWeight: FontWeight.w500,
                          //             color: AppColors.TextColor,
                          //           ),
                          //         ),
                          //   ),
                          // ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _checkBox() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isAccepted = !isAccepted;
        });
      },
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isAccepted ? AppColors.PrimaryColor : Colors.grey.shade400,
        ),
        child: isAccepted
            ? const Icon(
          Icons.check,
          size: 20,
          color: Colors.white,
        )
            : null,
      ),
    );
  }
}
