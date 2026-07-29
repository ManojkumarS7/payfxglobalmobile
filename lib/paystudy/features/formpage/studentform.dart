// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:loader_overlay/loader_overlay.dart';
// import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
// import 'package:payfxglobal/widgets/custom_text_field.dart';
// import 'package:payfxglobal/paystudy/core/constants/app_dropfield.dart';
// import 'package:payfxglobal/paystudy/core/providers/student_form/student_form_provider.dart';
// import 'package:payfxglobal/paystudy/features/formpage/studentform_2.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:payfxglobal/paystudy/model/LoanSubmitModel/loan_applicationdata.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:payfxglobal/paystudy/features/formpage/universityform.dart';
// import 'package:payfxglobal/paystudy/core/base_url/base_url.dart';
// import 'package:payfxglobal/paystudy/core/network/api_service.dart';
// import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
// import 'package:payfxglobal/utils/user_storage.dart';
//
// class StudentFormPage extends ConsumerStatefulWidget {
//   final LoanApplicationdata? existingData;
//   const StudentFormPage({Key? key, this.existingData}) : super(key: key);
//
//   @override
//   ConsumerState<StudentFormPage> createState() => _StudentFormPageState();
// }
//
// class _StudentFormPageState extends ConsumerState<StudentFormPage> {
//
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _nameController;
//   late TextEditingController _phoneController;
//   late TextEditingController _whatsappController;
//   late TextEditingController _emailController;
//   late TextEditingController _incomeController;
//   late TextEditingController _workexperienceController;
//   late TextEditingController _schoolController;
//
//
//   //Focus
//
//   final _namefocus = FocusNode();
//   final _phonefocus = FocusNode();
//   final _whatsappfocus = FocusNode();
//   final _emailfocus = FocusNode();
//   final _incomefocus = FocusNode();
//   final _workexperiencefocus = FocusNode();
//   final _schoolfocus = FocusNode();
//
//   final _backlogfocus = FocusNode();
//   final _testfocus = FocusNode();
//
//
//
//
//   final ApiService _apiService = ApiService();
//
//   final _storage = const FlutterSecureStorage();
//   Map<String, TextEditingController> _testScoreControllers = {};
//
//   List<String> _schoolSuggestions = [];
//   bool _showSuggestions = false;
//
//   late LoanApplicationdata formData;
//
//   final Map<String, Map<String, dynamic>> _testRange = {
//     'IELTS': {'min': 0.0, 'max': 9.0, 'step': 0.5},
//     'TOEFL': {'min': 0, 'max': 120, 'step': 1},
//     'GMAT': {'min': 0, 'max': 800, 'step': 10},
//     'GRE Verbal': {'min': 130, 'max': 170, 'step': 1},
//     'GRE Quant': {'min': 130, 'max': 170, 'step': 1},
//     'GRE Analytical Writing': {'min': 0.0, 'max': 6.0, 'step': 0.5},
//     'PTE': {'min': 0, 'max': 90, 'step': 1},
//     'DUOLINGO': {'min': 0, 'max': 160, 'step': 5},
//   };
//
//
//
//
//   @override
//   void initState() {
//     super.initState();
//     formData = widget.existingData ?? LoanApplicationdata();
//
//     _nameController = TextEditingController(text: formData.student_name);
//     _phoneController = TextEditingController(text: formData.phone);
//     _whatsappController = TextEditingController(text: formData.whatsapp_number);
//     _emailController = TextEditingController(text: formData.email);
//     _incomeController = TextEditingController(text: formData.monthly_income);
//     _workexperienceController = TextEditingController(text: formData.work_experince);
//     _schoolController = TextEditingController(text: formData.highest_degree);
//
//     _loadPayfxUserId();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final state = ref.read(studentFormProvider);
//       for (var test in state.selectedTests) {
//         if (test == 'GRE') {
//           _testScoreControllers['GRE Verbal'] = TextEditingController(text: formData.gre_verbal);
//           _testScoreControllers['GRE Quant'] = TextEditingController(text: formData.gre_quant);
//           _testScoreControllers['GRE Analytical Writing'] = TextEditingController(text: formData.gre_analytical_writing);
//         } else if (test != 'None') {
//           String score = '';
//           if (test == 'GMAT') score = formData.gmat_score ?? '';
//           if (test == 'IELTS') score = formData.ielts_score ?? '';
//           if (test == 'TOEFL') score = formData.toefl_score ?? '';
//           if (test == 'PTE') score = formData.pte_score ?? '';
//           if (test == 'DUOLINGO') score = formData.duolingo_score ?? '';
//           _testScoreControllers[test] = TextEditingController(text: score);
//         }
//       }
//     });
//   }
//
//   Future<void> _loadPayfxUserId() async {
//     final userData = await UserStorage.getUserData();
//     if (userData.isNotEmpty) {
//       String? userId;
//       if (userData.containsKey('customer')) {
//         userId = userData['customer']['id']?.toString();
//       } else {
//         userId = userData['id']?.toString();
//       }
//       if (userId != null) {
//         setState(() {
//           formData.payfx_user_id = userId;
//         });
//         debugPrint('Loaded payfx_user_id: $userId');
//       }
//     }
//   }
//
//   Future<void> phoneNumberVerify(String value) async {
//     if (value.length != 10) return;
//
//     try {
//       final formData = FormData.fromMap({
//         'phone': value,
//       });
//
//       final response = await _apiService.post(
//         'home/check_applicant_data',
//         data: formData,
//       );
//
//
//       dynamic data = response.data;
//
//       if (data is String) {
//         data = jsonDecode(data);
//       }
//
//       debugPrint("Decoded Response: $data");
//
//       if (data['status'] == 'exists' &&
//           (widget.existingData == null ||
//               value != widget.existingData!.phone)) {
//
//
//         AppSnackbar.show(context, 'Phone number already exists', success: false);
//
//
//         setState(() {
//           _phoneController.clear();
//         });
//       }
//     } catch (e) {
//       debugPrint('Phone verify error: $e');
//     }
//   }
//
//
//   Future<void> fetchSchoolSuggestions(String query) async {
//     if (query.length < 2) {
//       setState(() {
//         _schoolSuggestions.clear();
//         _showSuggestions = false;
//       });
//       return;
//     }
//
//     try {
//       final response = await _apiService.get(
//         'home/search_colleges',
//         queryParameters: {'q': query},
//       );
//
//       dynamic data = response.data;
//
//       if (data is String) {
//         data = jsonDecode(data);
//       }
//
//       List<String> suggestions = [];
//
//       if (data is List) {
//         suggestions = data.map((e) => e.toString()).toList();
//       }
//
//       setState(() {
//         _schoolSuggestions = suggestions;
//         _showSuggestions = suggestions.isNotEmpty;
//       });
//     } catch (e) {
//       debugPrint("School suggestion error: $e");
//     }
//   }
//
//
//   @override
//   void dispose() {
//
//     _namefocus.dispose();
//     _phonefocus.dispose();
//     _whatsappfocus.dispose();
//     _emailfocus.dispose();
//     _incomefocus.dispose();
//     _workexperiencefocus.dispose();
//     _schoolfocus.dispose();
//     _backlogfocus.dispose();
//     _testfocus.dispose();
//     _nameController.dispose();
//     _phoneController.dispose();
//     _whatsappController.dispose();
//     _emailController.dispose();
//     _schoolController.dispose();
//     _incomeController.dispose();
//     _workexperienceController.dispose();
//     _testScoreControllers.forEach((key, controller) => controller.dispose());
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final studentFormState = ref.watch(studentFormProvider);
//     final notifier = ref.read(studentFormProvider.notifier);
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         scrolledUnderElevation: 0.0,
//         surfaceTintColor: Colors.transparent,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: AppColors.TextColor),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: const Text(
//           'Check Eligibility',
//           style: TextStyle(
//             color: AppColors.TextColor,
//             fontSize: 20,
//             fontWeight: FontWeight.w500,
//             fontFamily: 'Satoshi',
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Student Details',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontFamily: 'Satoshi',
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.TextColor,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 AppTextField(controller: _nameController, hintText: 'Name', labelText: 'Name',focusNode: _namefocus,textInputAction: TextInputAction.next,         onFieldSubmitted: (_) =>
//                     FocusScope.of(context).requestFocus(_phonefocus),),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Select Gender',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontFamily: 'Satoshi',
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     _buildRadioOption('Male', studentFormState.gender == 'Male', () {
//                       notifier.setGender('Male');
//                     }),
//                     const SizedBox(width: 24),
//                     _buildRadioOption('Female', studentFormState.gender == 'Female', () {
//                       notifier.setGender('Female');
//                     }),
//                     const SizedBox(width: 24),
//                     _buildRadioOption('Others', studentFormState.gender == 'Others', () {
//                       notifier.setGender('Others');
//                     }),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 AppTextField(
//                       focusNode: _phonefocus,
//                       textInputAction: TextInputAction.next,
//                       onFieldSubmitted: (_) {
//                         if (!ref.read(studentFormProvider).isWhatsappNumber) {
//                           FocusScope.of(context).requestFocus(_whatsappfocus);
//                         } else {
//                           FocusScope.of(context).requestFocus(_emailfocus);
//                         }
//                       },
//                   controller: _phoneController,
//                   labelText: 'Phone number',
//                   hintText: 'Phone number',
//                   keyboardType: TextInputType.phone,
//                   onChanged: phoneNumberVerify,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Phone number is required';
//                     }
//                     final phoneRegex = RegExp(r'^[6-9]\d{9}$');
//                     if (!phoneRegex.hasMatch(value)) {
//                       return 'Please enter a valid 10-digit phone number';
//                     }
//                     return null;
//                   },
//                 ),
//
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Is the above number on whatsapp',
//                   style: TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     _buildRadioOption('Yes', studentFormState.isWhatsappNumber, () {
//                       notifier.setWhatsapp(true);
//                     }),
//                     const SizedBox(width: 24),
//                     _buildRadioOption('No', !studentFormState.isWhatsappNumber, () {
//                       notifier.setWhatsapp(false);
//                     }),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 if (!studentFormState.isWhatsappNumber)
//                   AppTextField(
//                     focusNode: _whatsappfocus,textInputAction: TextInputAction.next,         onFieldSubmitted: (_) =>
//                       FocusScope.of(context).requestFocus(_emailfocus),
//                     labelText: 'Whatsapp number',
//                     controller: _whatsappController,
//                     hintText: 'Enter Whatsapp number',
//                     keyboardType: TextInputType.phone,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Whatsapp number is required';
//                       }
//                       final phoneRegex = RegExp(r'^[6-9]\d{9}$');
//                       if (!phoneRegex.hasMatch(value)) {
//                         return 'Please enter a valid 10-digit whatsapp number';
//                       }
//                       return null;
//                     },
//                   ),
//                 if (!studentFormState.isWhatsappNumber) const SizedBox(height: 16),
//                 AppTextField(
//                   focusNode: _emailfocus,textInputAction: TextInputAction.next,         onFieldSubmitted: (_) =>
//                     FocusScope.of(context).requestFocus(_schoolfocus),
//                   controller: _emailController,
//                   labelText: 'Email',
//                   hintText: 'Email',
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Email is required';
//                     }
//                     final emailRegex = RegExp(
//                         r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
//                     if (!emailRegex.hasMatch(value)) {
//                       return 'Please enter a valid email address';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 AppTextField(
//                   focusNode: _schoolfocus,textInputAction: TextInputAction.next,         onFieldSubmitted: (_) =>
//                     FocusScope.of(context).requestFocus(_backlogfocus),
//                   controller: _schoolController,
//                   labelText: 'Highest School / College Name',
//                   hintText: 'Your Highest School / College Name',
//                   onChanged: fetchSchoolSuggestions,
//                 ),
//                 if (_showSuggestions)
//                   Container(
//                     margin: const EdgeInsets.only(top: 6),
//                     padding: const EdgeInsets.symmetric(vertical: 4),
//                     constraints: const BoxConstraints(maxHeight: 200),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: Colors.grey.shade300),
//                     ),
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: _schoolSuggestions.length,
//                       itemBuilder: (context, index) {
//                         final name = _schoolSuggestions[index];
//                         return ListTile(
//                           title: Text(name),
//                           onTap: () {
//                             _schoolController.text = name;
//                             setState(() => _showSuggestions = false);
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 const SizedBox(height: 16),
//                 AppDropdownField(
//                   labelText: 'Backlogs',
//                   hintText: 'Backlogs',
//                   value: studentFormState.backlog,
//                   items: ['0', '1', '2', '3', '4', '5', '5>'],
//                   onChanged: (value) {
//                     notifier.setBacklog(value);
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 AppTextField(
//                   focusNode: _workexperiencefocus,textInputAction: TextInputAction.next,         onFieldSubmitted: (_) =>
//                     FocusScope.of(context).requestFocus(_incomefocus),
//                   labelText: 'Work Experience',
//                   controller: _workexperienceController,
//                   hintText: 'Work Experience (in months eg:12)',
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 16),
//                 AppTextField(
//                   focusNode: _incomefocus,textInputAction: TextInputAction.done,         onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
//                   controller: _incomeController,
//                   labelText: 'Applicants monthly income',
//                   hintText: 'Applicants monthly income',
//                   keyboardType: TextInputType.number,
//                   validator: (value) {
//                     final workExp = int.tryParse(_workexperienceController.text) ?? 0;
//                     if (workExp > 0) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Monthly income is required';
//                       }
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Select the test\'s you have taken',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontFamily: 'Satoshi',
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Wrap(
//                   spacing: 24,
//                   runSpacing: 16,
//                   children: ['GRE','GMAT','IELTS','TOEFL','PTE','DUOLINGO','None']
//                       .map(
//                         (test) => _buildCheckboxOption(
//                           test,
//                           studentFormState.selectedTests.contains(test),
//                           () {
//                             notifier.toggleTest(test);
//                             setState(() {
//                               if (test == 'None') {
//                                 _testScoreControllers.forEach((_, controller) => controller.dispose());
//                                 _testScoreControllers.clear();
//                               } else if (studentFormState.selectedTests.contains(test)) {
//                                 if (test == 'GRE') {
//                                   _testScoreControllers['GRE Verbal']?.dispose();
//                                   _testScoreControllers.remove('GRE Verbal');
//                                   _testScoreControllers['GRE Quant']?.dispose();
//                                   _testScoreControllers.remove('GRE Quant');
//                                   _testScoreControllers['GRE Analytical Writing']?.dispose();
//                                   _testScoreControllers.remove('GRE Analytical Writing');
//                                 } else {
//                                   _testScoreControllers[test]?.dispose();
//                                   _testScoreControllers.remove(test);
//                                 }
//                               } else {
//                                 if (test == 'GRE') {
//                                   _testScoreControllers['GRE Verbal'] = TextEditingController();
//                                   _testScoreControllers['GRE Quant'] = TextEditingController();
//                                   _testScoreControllers['GRE Analytical Writing'] = TextEditingController();
//                                 } else {
//                                   _testScoreControllers[test] = TextEditingController();
//                                 }
//                               }
//                             });
//                           },
//                         ),
//                       )
//                       .toList(),
//                 ),
//                 const SizedBox(height: 16),
//                 ..._buildTestScoreFields(studentFormState.selectedTests),
//                 const SizedBox(height: 40),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     onPressed: _submitForm,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: AppColors.PrimaryColor,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(28),
//                         side: BorderSide(color: AppColors.PrimaryColor!, width: 2),
//                       ),
//                     ),
//                     child: const Text(
//                       'Next',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontFamily: 'Satoshi',
//                         fontWeight: FontWeight.w500,
//                         color: AppColors.TextColor,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   List<Widget> _buildTestScoreFields(List<String> selectedTests) {
//     List<Widget> fields = [];
//     final orderedList = ['GRE', 'GMAT', 'IELTS', 'TOEFL', 'PTE', 'DUOLINGO'];
//     for (String test in orderedList) {
//       if (selectedTests.contains(test)) {
//         if (test == 'GRE') {
//           fields.add(_buildScoreInputField('GRE Verbal'));
//           fields.add(const SizedBox(height: 16));
//           fields.add(_buildScoreInputField('GRE Quant'));
//           fields.add(const SizedBox(height: 16));
//           fields.add(_buildScoreInputField('GRE Analytical Writing'));
//           fields.add(const SizedBox(height: 16));
//         } else {
//           fields.add(_buildScoreInputField(test));
//           fields.add(const SizedBox(height: 16));
//         }
//       }
//     }
//     return fields;
//   }
//
//   Widget _buildScoreInputField(String test) {
//     final range = _testRange[test];
//     final controller = _testScoreControllers[test] ?? TextEditingController();
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           '$test Score',
//           style: const TextStyle(
//             fontSize: 14,
//             fontFamily: 'Satoshi',
//             fontWeight: FontWeight.w500,
//             color: Colors.grey,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey[300]!),
//           ),
//           child: TextFormField(
//             controller: controller,
//             keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             style: const TextStyle(
//               fontSize: 16,
//               fontFamily: 'Satoshi',
//               fontWeight: FontWeight.w500,
//               color: AppColors.TextColor,
//             ),
//             decoration: InputDecoration(
//               hintText: 'Enter score (${range!['min']} - ${range['max']})',
//               hintStyle: TextStyle(
//                 fontSize: 14,
//                 fontFamily: 'Satoshi',
//                 color: Colors.grey[500],
//               ),
//               suffixIcon: Padding(
//                 padding: const EdgeInsets.only(right: 12),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       '/ ${range['max']}',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontFamily: 'Satoshi',
//                         color: Colors.grey[600],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               border: InputBorder.none,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             ),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter your $test score';
//               }
//               final score = double.tryParse(value);
//               if (score == null) {
//                 return 'Please enter a valid number';
//               }
//               if (score < range['min'] || score > range['max']) {
//                 return 'Score must be between ${range['min']} and ${range['max']}';
//               }
//               return null;
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCheckboxOption(String label, bool isSelected, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 20,
//             height: 20,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(4),
//               border: Border.all(
//                 color: isSelected ? AppColors.PrimaryColor! : Colors.grey[400]!,
//                 width: 2,
//               ),
//               color: isSelected ? AppColors.PrimaryColor : Colors.transparent,
//             ),
//             child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 16,
//               fontFamily: 'Satoshi',
//               fontWeight: FontWeight.w500,
//               color: isSelected ? AppColors.TextColor : Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRadioOption(String label, bool isSelected, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Row(
//         children: [
//           Container(
//             width: 20,
//             height: 20,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: isSelected ? AppColors.PrimaryColor! : Colors.grey[400]!,
//                 width: 2,
//               ),
//             ),
//             child: isSelected
//                 ? Center(
//                     child: Container(
//                       width: 10,
//                       height: 10,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: AppColors.PrimaryColor,
//                       ),
//                     ),
//                   )
//                 : null,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 16,
//               fontFamily: 'Satoshi',
//               fontWeight: FontWeight.w500,
//               color: isSelected ? AppColors.TextColor : Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _submitForm() async {
//
//     if (!_formKey.currentState!.validate()) return;
//
//     final studentFormState = ref.read(studentFormProvider);
//
//
//     await _storage.write(key: 'studentNumber', value: _phoneController.text);
//
//
//     formData.payfx_user_id ;
//
//
//
//
//     print('user_id ${formData.payfx_user_id}'.runtimeType);
//
//     formData.student_name = _nameController.text;
//     formData.gender = studentFormState.gender;
//     formData.phone = _phoneController.text;
//     formData.isWhatsappNumber = studentFormState.isWhatsappNumber ? 'Yes' : 'No';
//     formData.whatsapp_number = !studentFormState.isWhatsappNumber ? _whatsappController.text : _phoneController.text;
//     formData.email = _emailController.text;
//     formData.highest_degree = _schoolController.text;
//     formData.backlogs = studentFormState.backlog;
//     formData.work_experince = _workexperienceController.text;
//     formData.monthly_income = _incomeController.text;
//
//     final orderedList = ['GRE', 'GMAT', 'IELTS', 'TOEFL', 'PTE', 'DUOLINGO'];
//     List<String> sortedSelected = [];
//     for (var test in orderedList) {
//       if (studentFormState.selectedTests.contains(test)) sortedSelected.add(test);
//     }
//     if (studentFormState.selectedTests.contains('None')) sortedSelected.add('None');
//     formData.test_taken = sortedSelected.join(',');
//
//     formData.ielts_score = _testScoreControllers['IELTS']?.text;
//     formData.toefl_score = _testScoreControllers['TOEFL']?.text;
//     formData.gmat_score = _testScoreControllers['GMAT']?.text;
//     formData.gre_verbal = _testScoreControllers['GRE Verbal']?.text;
//     formData.gre_quant = _testScoreControllers['GRE Quant']?.text;
//     formData.gre_analytical_writing = _testScoreControllers['GRE Analytical Writing']?.text;
//     formData.pte_score = _testScoreControllers['PTE']?.text;
//     formData.duolingo_score = _testScoreControllers['DUOLINGO']?.text;
//
//
//     try {
//       final body = formData.toApiBody();
//
//       print(body);
//
//       final applicationid =
//       await _storage.read(key: 'applicant_id');
//
//       if (applicationid != null) {
//         body['applicant_id'] = applicationid;
//       }
//
//
//       final response = await _apiService.post(
//         'home/v1/api/loan_eligible_store',
//         data: FormData.fromMap(body),
//       );
//
//       debugPrint('STATUS: ${response.statusCode}');
//       debugPrint('BODY: ${response.data}');
//
//
//       dynamic responseData = response.data;
//
//       print(responseData);
//
//       if (responseData is String) {
//         responseData = jsonDecode(responseData);
//
//         print(responseData);
//       }
//
//       if (response.statusCode == 200 &&
//           responseData['status'] == 'success') {
//
//         final String? appId =
//         responseData['applicant_id']?.toString();
//
//         if (appId != null) {
//           await _storage.write(
//             key: 'applicant_id',
//             value: appId,
//           );
//
//           formData.application_id = appId;
//         }
//
//         if (mounted) {
//           // context.loaderOverlay.hide();
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) =>
//                   SecondStudentForm(formData: formData),
//             ),
//           );
//         }
//       }
//
//     } catch (e) {
//       context.loaderOverlay.hide();
//       debugPrint('Submit Error: $e');
//     }
//   }
// }

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/paystudy/core/constants/app_dropfield.dart';
import 'package:payfxglobal/paystudy/core/providers/student_form/student_form_provider.dart';
import 'package:payfxglobal/paystudy/features/formpage/studentform_2.dart';
import 'dart:convert';
import 'package:payfxglobal/paystudy/model/LoanSubmitModel/loan_applicationdata.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payfxglobal/paystudy/core/network/api_service.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/utils/user_storage.dart';

class StudentFormPage extends ConsumerStatefulWidget {
  final LoanApplicationdata? existingData;
  const StudentFormPage({Key? key, this.existingData}) : super(key: key);

  @override
  ConsumerState<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends ConsumerState<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _incomeController;
  late TextEditingController _workexperienceController;
  late TextEditingController _schoolController;

  // --- Focus nodes ---
  // FIX: All focus nodes are now disposed in dispose()
  final _namefocus = FocusNode();
  final _phonefocus = FocusNode();
  final _whatsappfocus = FocusNode();
  final _emailfocus = FocusNode();
  final _incomefocus = FocusNode();
  final _workexperiencefocus = FocusNode();
  final _schoolfocus = FocusNode();
  // FIX: _backlogfocus is now wired to a Focus wrapper around AppDropdownField
  final _backlogfocus = FocusNode();
  // FIX: _testfocus removed — test score fields are dynamic; no single static focus node applies

  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  Map<String, TextEditingController> _testScoreControllers = {};

  List<String> _schoolSuggestions = [];
  bool _showSuggestions = false;

  late LoanApplicationdata formData;

  // FIX: Track form readiness for button enable/disable
  bool _isFormReady = false;

  final Map<String, Map<String, dynamic>> _testRange = {
    'IELTS': {'min': 0.0, 'max': 9.0, 'step': 0.5},
    'TOEFL': {'min': 0, 'max': 120, 'step': 1},
    'GMAT': {'min': 0, 'max': 800, 'step': 10},
    'GRE Verbal': {'min': 130, 'max': 170, 'step': 1},
    'GRE Quant': {'min': 130, 'max': 170, 'step': 1},
    'GRE Analytical Writing': {'min': 0.0, 'max': 6.0, 'step': 0.5},
    'PTE': {'min': 0, 'max': 90, 'step': 1},
    'DUOLINGO': {'min': 0, 'max': 160, 'step': 5},
  };

  @override
  void initState() {
    super.initState();
    formData = widget.existingData ?? LoanApplicationdata();

    _nameController = TextEditingController(text: formData.student_name);
    _phoneController = TextEditingController(text: formData.phone);
    _whatsappController = TextEditingController(text: formData.whatsapp_number);
    _emailController = TextEditingController(text: formData.email);
    _incomeController = TextEditingController(text: formData.monthly_income);
    _workexperienceController = TextEditingController(text: formData.work_experince);
    _schoolController = TextEditingController(text: formData.highest_degree);

    // FIX: Listen to required field controllers to recompute button state
    for (final c in [
      _nameController,
      _phoneController,
      _emailController,
      _schoolController,
    ]) {
      c.addListener(_updateFormReady);
    }

    _loadPayfxUserId();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(studentFormProvider);
      for (var test in state.selectedTests) {
        if (test == 'GRE') {
          _testScoreControllers['GRE Verbal'] =
              TextEditingController(text: formData.gre_verbal);
          _testScoreControllers['GRE Quant'] =
              TextEditingController(text: formData.gre_quant);
          _testScoreControllers['GRE Analytical Writing'] =
              TextEditingController(text: formData.gre_analytical_writing);
        } else if (test != 'None') {
          String score = '';
          if (test == 'GMAT') score = formData.gmat_score ?? '';
          if (test == 'IELTS') score = formData.ielts_score ?? '';
          if (test == 'TOEFL') score = formData.toefl_score ?? '';
          if (test == 'PTE') score = formData.pte_score ?? '';
          if (test == 'DUOLINGO') score = formData.duolingo_score ?? '';
          _testScoreControllers[test] = TextEditingController(text: score);
        }
      }
      // Initial check after data loads
      _updateFormReady();
    });
  }

  /// FIX: Centralized form readiness check — drives button enabled state.
  /// Checks all required fields and provider state together.
  void _updateFormReady() {
    final state = ref.read(studentFormProvider);
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");

    final ready = _nameController.text.trim().isNotEmpty &&
        phoneRegex.hasMatch(_phoneController.text) &&
        emailRegex.hasMatch(_emailController.text) &&
        _schoolController.text.trim().isNotEmpty &&
        state.gender != null &&
        state.gender!.isNotEmpty &&
        state.backlog != null;

    if (mounted && ready != _isFormReady) {
      setState(() => _isFormReady = ready);
    }
  }

  Future<void> _loadPayfxUserId() async {
    final userData = await UserStorage.getUserData();
    if (userData.isNotEmpty) {
      String? userId;
      if (userData.containsKey('customer')) {
        userId = userData['customer']['id']?.toString();
      } else {
        userId = userData['id']?.toString();
      }
      if (userId != null) {
        setState(() {
          formData.payfx_user_id = userId;
        });
        debugPrint('Loaded payfx_user_id: $userId');
      }
    }
  }

  Future<void> phoneNumberVerify(String value) async {
    if (value.length != 10) return;

    try {
      final formData = FormData.fromMap({'phone': value});
      final response = await _apiService.post(
        'home/check_applicant_data',
        data: formData,
      );

      dynamic data = response.data;
      if (data is String) data = jsonDecode(data);

      debugPrint("Decoded Response: $data");

      if (data['status'] == 'exists' &&
          (widget.existingData == null ||
              value != widget.existingData!.phone)) {
        AppSnackbar.show(context, 'Phone number already exists',
            success: false);
        setState(() => _phoneController.clear());
      }
    } catch (e) {
      debugPrint('Phone verify error: $e');
    }
  }

  Future<void> fetchSchoolSuggestions(String query) async {
    if (query.length < 2) {
      setState(() {
        _schoolSuggestions.clear();
        _showSuggestions = false;
      });
      return;
    }

    try {
      final response = await _apiService.get(
        'home/search_colleges',
        queryParameters: {'q': query},
      );

      dynamic data = response.data;
      if (data is String) data = jsonDecode(data);

      List<String> suggestions = [];
      if (data is List) {
        suggestions = data.map((e) => e.toString()).toList();
      }

      setState(() {
        _schoolSuggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {
      debugPrint("School suggestion error: $e");
    }
  }

  @override
  void dispose() {
    // FIX: Dispose all controllers
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _incomeController.dispose();
    _workexperienceController.dispose();
    _testScoreControllers.forEach((_, c) => c.dispose());

    // FIX: Dispose ALL focus nodes — previously missing, causing memory leaks
    _namefocus.dispose();
    _phonefocus.dispose();
    _whatsappfocus.dispose();
    _emailfocus.dispose();
    _incomefocus.dispose();
    _workexperiencefocus.dispose();
    _schoolfocus.dispose();
    _backlogfocus.dispose();
    // _testfocus removed entirely

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentFormState = ref.watch(studentFormProvider);
    final notifier = ref.read(studentFormProvider.notifier);

    // FIX: Re-evaluate readiness when provider state changes (gender, backlog, etc.)
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFormReady());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.TextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                  'Student Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w500,
                    color: AppColors.TextColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                AppTextField(
                  controller: _nameController,
                  hintText: 'Name',
                  labelText: 'Name',
                  focusNode: _namefocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_phonefocus),
                ),
                const SizedBox(height: 16),

                // Gender
                const Text(
                  'Select Gender',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Satoshi',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRadioOption('Male', studentFormState.gender == 'Male',
                            () => notifier.setGender('Male')),
                    const SizedBox(width: 24),
                    _buildRadioOption(
                        'Female',
                        studentFormState.gender == 'Female',
                            () => notifier.setGender('Female')),
                    const SizedBox(width: 24),
                    _buildRadioOption(
                        'Others',
                        studentFormState.gender == 'Others',
                            () => notifier.setGender('Others')),
                  ],
                ),
                const SizedBox(height: 16),

                // Phone
                // FIX: onFieldSubmitted conditionally routes to whatsapp OR email
                AppTextField(
                  focusNode: _phonefocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    if (!studentFormState.isWhatsappNumber) {
                      FocusScope.of(context).requestFocus(_whatsappfocus);
                    } else {
                      FocusScope.of(context).requestFocus(_emailfocus);
                    }
                  },
                  controller: _phoneController,
                  labelText: 'Phone number',
                  hintText: 'Phone number',
                  keyboardType: TextInputType.phone,
                  onChanged: phoneNumberVerify,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
                    if (!phoneRegex.hasMatch(value)) {
                      return 'Please enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // WhatsApp toggle
                const Text(
                  'Is the above number on whatsapp',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRadioOption(
                        'Yes', studentFormState.isWhatsappNumber, () {
                      notifier.setWhatsapp(true);
                      _updateFormReady();
                    }),
                    const SizedBox(width: 24),
                    _buildRadioOption(
                        'No', !studentFormState.isWhatsappNumber, () {
                      notifier.setWhatsapp(false);
                      _updateFormReady();
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // WhatsApp number (conditionally shown)
                if (!studentFormState.isWhatsappNumber) ...[
                  AppTextField(
                    focusNode: _whatsappfocus,
                    textInputAction: TextInputAction.next,
                    // FIX: WhatsApp field correctly advances to email
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_emailfocus),
                    labelText: 'Whatsapp number',
                    controller: _whatsappController,
                    hintText: 'Enter Whatsapp number',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Whatsapp number is required';
                      }
                      final phoneRegex = RegExp(r'^[6-9]\d{9}$');
                      if (!phoneRegex.hasMatch(value)) {
                        return 'Please enter a valid 10-digit whatsapp number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Email
                AppTextField(
                  focusNode: _emailfocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_schoolfocus),
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    final emailRegex = RegExp(
                        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // School / College
                // FIX: school → backlog focus (via Focus wrapper on dropdown)
                AppTextField(
                  focusNode: _schoolfocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_backlogfocus),
                  controller: _schoolController,
                  labelText: 'Highest School / College Name',
                  hintText: 'Your Highest School / College Name',
                  onChanged: fetchSchoolSuggestions,
                ),
                if (_showSuggestions)
                  Container(
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
                      itemCount: _schoolSuggestions.length,
                      itemBuilder: (context, index) {
                        final name = _schoolSuggestions[index];
                        return ListTile(
                          title: Text(name),
                          onTap: () {
                            _schoolController.text = name;
                            setState(() => _showSuggestions = false);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                // Backlogs dropdown
                // FIX: Wrapped in Focus so _backlogfocus correctly activates it
                // and advances to workexperience on selection/done
                Focus(
                  focusNode: _backlogfocus,
                  child: AppDropdownField(
                    labelText: 'Backlogs',
                    hintText: 'Backlogs',
                    value: studentFormState.backlog,
                    items: ['0', '1', '2', '3', '4', '5', '5>'],
                    onChanged: (value) {
                      notifier.setBacklog(value);
                      // Advance focus to work experience after selecting
                      FocusScope.of(context).requestFocus(_workexperiencefocus);
                      _updateFormReady();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Work Experience
                AppTextField(
                  focusNode: _workexperiencefocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_incomefocus),
                  labelText: 'Work Experience',
                  controller: _workexperienceController,
                  hintText: 'Work Experience (in months eg:12)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Monthly Income
                AppTextField(
                  focusNode: _incomefocus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                  controller: _incomeController,
                  labelText: 'Applicants monthly income',
                  hintText: 'Applicants monthly income',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final workExp =
                        int.tryParse(_workexperienceController.text) ?? 0;
                    if (workExp > 0) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Monthly income is required';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Test selection
                Text(
                  'Select the test\'s you have taken',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    'GRE',
                    'GMAT',
                    'IELTS',
                    'TOEFL',
                    'PTE',
                    'DUOLINGO',
                    'None'
                  ]
                      .map(
                        (test) => _buildCheckboxOption(
                      test,
                      studentFormState.selectedTests.contains(test),
                          () {
                        notifier.toggleTest(test);
                        setState(() {
                          if (test == 'None') {
                            _testScoreControllers
                                .forEach((_, c) => c.dispose());
                            _testScoreControllers.clear();
                          } else if (studentFormState.selectedTests
                              .contains(test)) {
                            if (test == 'GRE') {
                              _testScoreControllers['GRE Verbal']
                                  ?.dispose();
                              _testScoreControllers.remove('GRE Verbal');
                              _testScoreControllers['GRE Quant']?.dispose();
                              _testScoreControllers.remove('GRE Quant');
                              _testScoreControllers[
                              'GRE Analytical Writing']
                                  ?.dispose();
                              _testScoreControllers
                                  .remove('GRE Analytical Writing');
                            } else {
                              _testScoreControllers[test]?.dispose();
                              _testScoreControllers.remove(test);
                            }
                          } else {
                            if (test == 'GRE') {
                              _testScoreControllers['GRE Verbal'] =
                                  TextEditingController();
                              _testScoreControllers['GRE Quant'] =
                                  TextEditingController();
                              _testScoreControllers[
                              'GRE Analytical Writing'] =
                                  TextEditingController();
                            } else {
                              _testScoreControllers[test] =
                                  TextEditingController();
                            }
                          }
                        });
                      },
                    ),
                  )
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Dynamic test score fields
                // FIX: _testfocus removed; each dynamic field uses TextInputAction.next
                // and unfocuses after the last one since count is unknown at build time
                ..._buildTestScoreFields(studentFormState.selectedTests),
                const SizedBox(height: 40),

                // FIX: Button is disabled until all required fields are valid
                // SizedBox(
                //   width: double.infinity,
                //   height: 56,
                //   child: ElevatedButton(
                //     onPressed: _isFormReady ? _submitForm : null,
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
                //     child: Text(
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

                AppPrimaryButton(title: 'Next', onPressed:  _isFormReady ? _submitForm : null,),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTestScoreFields(List<String> selectedTests) {
    List<Widget> fields = [];
    final orderedList = ['GRE', 'GMAT', 'IELTS', 'TOEFL', 'PTE', 'DUOLINGO'];
    final activeTests = orderedList
        .where((t) => selectedTests.contains(t))
        .expand((t) => t == 'GRE'
        ? ['GRE Verbal', 'GRE Quant', 'GRE Analytical Writing']
        : [t])
        .toList();

    for (int i = 0; i < activeTests.length; i++) {
      final isLast = i == activeTests.length - 1;
      fields.add(_buildScoreInputField(activeTests[i], isLast: isLast));
      fields.add(const SizedBox(height: 16));
    }
    return fields;
  }

  Widget _buildScoreInputField(String test, {bool isLast = false}) {
    final range = _testRange[test];
    final controller =
        _testScoreControllers[test] ?? TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$test Score',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: controller,
            // FIX: last test score field dismisses keyboard; others advance
            textInputAction:
            isLast ? TextInputAction.done : TextInputAction.next,
            onFieldSubmitted: (_) {
              if (isLast) FocusScope.of(context).unfocus();
            },
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
              color: AppColors.TextColor,
            ),
            decoration: InputDecoration(
              hintText: 'Enter score (${range!['min']} - ${range['max']})',
              hintStyle: TextStyle(
                fontSize: 14,
                fontFamily: 'Satoshi',
                color: Colors.grey[500],
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '/ ${range['max']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Satoshi',
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your $test score';
              }
              final score = double.tryParse(value);
              if (score == null) {
                return 'Please enter a valid number';
              }
              if (score < range['min'] || score > range['max']) {
                return 'Score must be between ${range['min']} and ${range['max']}';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxOption(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color:
                isSelected ? AppColors.PrimaryColor! : Colors.grey[400]!,
                width: 2,
              ),
              color: isSelected ? AppColors.PrimaryColor : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.TextColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                isSelected ? AppColors.PrimaryColor! : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.PrimaryColor,
                ),
              ),
            )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.TextColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    // FIX: Validate and auto-focus the first failing required field
    if (!_formKey.currentState!.validate()) {
      _focusFirstError();
      return;
    }

    final studentFormState = ref.read(studentFormProvider);

    await _storage.write(key: 'studentNumber', value: _phoneController.text);

    formData.payfx_user_id ;
    print('user_id ${formData.payfx_user_id}'.runtimeType);

    formData.student_name = _nameController.text;
    formData.gender = studentFormState.gender;
    formData.phone = _phoneController.text;
    formData.isWhatsappNumber =
    studentFormState.isWhatsappNumber ? 'Yes' : 'No';
    formData.whatsapp_number = !studentFormState.isWhatsappNumber
        ? _whatsappController.text
        : _phoneController.text;
    formData.email = _emailController.text;
    formData.highest_degree = _schoolController.text;
    formData.backlogs = studentFormState.backlog;
    formData.work_experince = _workexperienceController.text;
    formData.monthly_income = _incomeController.text;

    final orderedList = ['GRE', 'GMAT', 'IELTS', 'TOEFL', 'PTE', 'DUOLINGO'];
    List<String> sortedSelected = [];
    for (var test in orderedList) {
      if (studentFormState.selectedTests.contains(test)) {
        sortedSelected.add(test);
      }
    }
    if (studentFormState.selectedTests.contains('None')) {
      sortedSelected.add('None');
    }
    formData.test_taken = sortedSelected.join(',');

    formData.ielts_score = _testScoreControllers['IELTS']?.text;
    formData.toefl_score = _testScoreControllers['TOEFL']?.text;
    formData.gmat_score = _testScoreControllers['GMAT']?.text;
    formData.gre_verbal = _testScoreControllers['GRE Verbal']?.text;
    formData.gre_quant = _testScoreControllers['GRE Quant']?.text;
    formData.gre_analytical_writing =
        _testScoreControllers['GRE Analytical Writing']?.text;
    formData.pte_score = _testScoreControllers['PTE']?.text;
    formData.duolingo_score = _testScoreControllers['DUOLINGO']?.text;

    try {
      final body = formData.toApiBody();
      debugPrint(body.toString());

      final applicationid = await _storage.read(key: 'applicant_id');
      if (applicationid != null) {
        body['applicant_id'] = applicationid;
      }

      final response = await _apiService.post(
        'home/v1/api/loan_eligible_store',
        data: FormData.fromMap(body),
      );

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.data}');

      dynamic responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final String? appId = responseData['applicant_id']?.toString();

        if (appId != null) {
          await _storage.write(key: 'applicant_id', value: appId);
          formData.application_id = appId;
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SecondStudentForm(formData: formData),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) context.loaderOverlay.hide();
      debugPrint('Submit Error: $e');
    }
  }

  /// FIX: Focus the first field that failed validation so the user
  /// knows exactly where to look after pressing Next.
  void _focusFirstError() {
    final state = ref.read(studentFormProvider);

    if (_nameController.text.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_namefocus);
    } else if (state.gender == null || state.gender!.isEmpty) {
      // Gender is radio — just scroll up, no focusable node
    } else {
      final phoneRegex = RegExp(r'^[6-9]\d{9}$');
      if (!phoneRegex.hasMatch(_phoneController.text)) {
        FocusScope.of(context).requestFocus(_phonefocus);
      } else if (!state.isWhatsappNumber) {
        final waRegex = RegExp(r'^[6-9]\d{9}$');
        if (!waRegex.hasMatch(_whatsappController.text)) {
          FocusScope.of(context).requestFocus(_whatsappfocus);
        }
      } else {
        final emailRegex = RegExp(
            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
        if (!emailRegex.hasMatch(_emailController.text)) {
          FocusScope.of(context).requestFocus(_emailfocus);
        } else if (_schoolController.text.trim().isEmpty) {
          FocusScope.of(context).requestFocus(_schoolfocus);
        } else if (state.backlog == null) {
          FocusScope.of(context).requestFocus(_backlogfocus);
        } else {
          final workExp =
              int.tryParse(_workexperienceController.text) ?? 0;
          if (workExp > 0 && _incomeController.text.trim().isEmpty) {
            FocusScope.of(context).requestFocus(_incomefocus);
          }
        }
      }
    }
  }
}