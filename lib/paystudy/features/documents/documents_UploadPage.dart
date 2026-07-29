import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payfxglobal/paystudy/core/constants/app_textfield.dart';
import 'package:payfxglobal/paystudy/core/network/api_service.dart';
import 'package:payfxglobal/paystudy/core/constants/app_radio_button.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/paystudy/core/constants/dashboard.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';

class DocumentsUploadpage extends StatefulWidget {
  const DocumentsUploadpage({super.key});

  @override
  State<DocumentsUploadpage> createState() => _DocumentsUploadpageState();
}

class _DocumentsUploadpageState extends State<DocumentsUploadpage> {
  final _storage = const FlutterSecureStorage();
  static const String loanNoKey = 'loan_ref_no';

  File? studentFile;
  File? coApplicantFile;
  bool isLoading = true;
  bool isVerifying = false;
  bool isUploading = false;
  
  final ApiService _apiService = ApiService();

  String? selectedApplicantId;
  String? selectedLoanNo;
  List<dynamic> applications = [];
  int? fxglbUserId;
  final TextEditingController _loanNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => isLoading = true);
    await _fetchUserId();
    if (fxglbUserId != null) {
      await _fetchApplications();
    }
    await _loadPersistedSelection();
    setState(() => isLoading = false);
  }

  Future<void> _fetchUserId() async {
    try {
      final userData = await UserStorage.getUserData();
      if (userData.isNotEmpty) {
        final customer = userData['customer'];
        if (customer != null) {
          fxglbUserId = int.tryParse(customer['id']?.toString() ?? '');
        } else {
          fxglbUserId = int.tryParse(userData['id']?.toString() ?? '');
        }
      }
    } catch (e) {
      debugPrint('Error fetching user ID: $e');
    }
  }

  Future<void> _fetchApplications() async {
    try {
      final response = await _apiService.get('home/v1/api/loan_applicant_list/$fxglbUserId');
      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) data = json.decode(data);
        if (data['status'] == 'success') {
          setState(() {
            applications = data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching applications: $e');
    }
  }

  Future<void> _loadPersistedSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLoanNo = prefs.getString(loanNoKey);
    final savedApplicantId = await _storage.read(key: 'selected_applicant_id');

    if (savedApplicantId != null && applications.any((a) => a['applicant_id'].toString() == savedApplicantId)) {
      selectedApplicantId = savedApplicantId;
      final app = applications.firstWhere((a) => a['applicant_id'].toString() == savedApplicantId);
      selectedLoanNo = app['loan_ref_no']?.toString();
    } else if (savedLoanNo != null && applications.any((a) => a['loan_ref_no'].toString() == savedLoanNo)) {
      selectedLoanNo = savedLoanNo;
      final app = applications.firstWhere((a) => a['loan_ref_no'].toString() == savedLoanNo);
      selectedApplicantId = app['applicant_id'].toString();
      await _storage.write(key: 'selected_applicant_id', value: selectedApplicantId);
    } else if (applications.isNotEmpty) {
      final firstApp = applications.first;
      selectedApplicantId = firstApp['applicant_id'].toString();
      selectedLoanNo = firstApp['loan_ref_no']?.toString();
      await _persistSelection(selectedLoanNo!, selectedApplicantId!);
    }
  }

  Future<void> _persistSelection(String loanNo, String applicantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(loanNoKey, loanNo);
    await _storage.write(key: 'selected_applicant_id', value: applicantId);
  }

  Future<void> _onApplicationSelected(dynamic app) async {
    final loanNo = app['loan_ref_no']?.toString();
    final applicantId = app['applicant_id']?.toString();

    if (loanNo != null && applicantId != null) {
      setState(() {
        selectedLoanNo = loanNo;
        selectedApplicantId = applicantId;
      });
      await _persistSelection(loanNo, applicantId);
    }
  }

  Future<void> _verifyLoanNumber() async {
    final number = _loanNumberController.text.trim();
    if (number.isEmpty) return;

    setState(() => isVerifying = true);

    try {
      final response = await _apiService.post(
        'home/v1/api/loan_check_status',
        data: FormData.fromMap({'loan_number': number}),
      );

      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) data = json.decode(data);

        if (data['status'] == 'success') {
          final details = data['data'] ?? data;
          final applicantId = details['applicant_id']?.toString();

          if (applicantId != null) {
            await _persistSelection(number, applicantId);
            await _fetchApplications();

            setState(() {
              selectedLoanNo = number;
              selectedApplicantId = applicantId;
            });
          }

          if (mounted) {
            Navigator.pop(context);
            AppSnackbar.show(context, 'Loan number verified successfully');
          }
        } else {
          throw Exception(data['message'] ?? 'Invalid loan number');
        }
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Verification failed', success: false);
      }
    } finally {
      if (mounted) setState(() => isVerifying = false);
    }
  }

  Future<void> pickFile(bool isStudent) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        if (isStudent) {
          studentFile = File(result.files.single.path!);
        } else {
          coApplicantFile = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> uploadDocuments() async {
    if (selectedApplicantId == null) {
      AppSnackbar.show(context, 'Please select an application first', success: false);
      return;
    }
    if (studentFile == null && coApplicantFile == null) {
      AppSnackbar.show(context, 'Please select any one document', success: false);
      return;
    }

    setState(() => isUploading = true);

    try {
      final Map<String, dynamic> dataMap = {
        'applicant_id': selectedApplicantId,
      };

      if (studentFile != null) {
        dataMap['student_zip'] = await MultipartFile.fromFile(studentFile!.path, filename: studentFile!.path.split('/').last);
      }
      if (coApplicantFile != null) {
        dataMap['coapplicant_zip'] = await MultipartFile.fromFile(coApplicantFile!.path, filename: coApplicantFile!.path.split('/').last);
      }

      final response = await _apiService.post(
        'home/v1/api/upload_student_coapplicant_pdf',
        data: FormData.fromMap(dataMap),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          AppSnackbar.show(context, 'Documents upload successfully');
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Upload failed', success: false);
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.TextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        title: const Text(
          'Upload Your Documents',
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
          ? const Center(child: CustomLoadingIndicator())
          : (applications.isEmpty ? _NoLoanUI(context) : _DocumentUploadUI()),
    );
  }

  void _showLoanPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter Your Loan Number',
                    style: TextStyle(
                      color: AppColors.TextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _loanNumberController,
                    labelText: 'Loan Number',
                    hintText: 'eg: LOAN-REF-2026-0001',
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    title: 'Verify',
                    onPressed: isVerifying ? null : () async {
                      setDialogState(() => isVerifying = true);
                      await _verifyLoanNumber();
                      if (mounted) {
                        setDialogState(() => isVerifying = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _NoLoanUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Documents',
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              color: AppColors.TextColor,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.TextColor,
                width: 1.2,
              ),
            ),
            child: const Text(
              'Please first check and confirm your eligibility. Once your eligibility is confirmed, the required document checklist will be sent to you on this WhatsApp number. After receiving the checklist, kindly upload all the required documents for further processing..',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w500,
                color: AppColors.TextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 50),

          AppPrimaryButton(title: 'Check Eligibility',onPressed: () => Navigator.of(context).pop(), )
          // SizedBox(
          //   height: 50,
          //   width: double.infinity,
          //   child: OutlinedButton(
          //     onPressed: _showLoanPopup,
          //     style: OutlinedButton.styleFrom(
          //       side: BorderSide(
          //         color: AppColors.PrimaryColor!,
          //         width: 1.5,
          //       ),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(30),
          //       ),
          //     ),
          //     child: const Text(
          //       'Verify Loan Number',
          //       style: TextStyle(
          //         fontSize: 18,
          //         fontFamily: 'Satoshi',
          //         fontWeight: FontWeight.w500,
          //         color: AppColors.TextColor,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _DocumentUploadUI() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Application',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.TextColor,
              ),
            ),
            const SizedBox(height: 12),
            ...applications.map((app) {
              final appLoanNo = app['loan_ref_no']?.toString() ?? '';
              final appId = app['applicant_id']?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppRadioTile<String>(
                  groupValue: selectedApplicantId as String,
                  title: app['applicant_name']?.toString() ?? "Active Application",
                  value: appId,
                  subtitle: appLoanNo,
                  onChanged: (val) => _onApplicationSelected(app),
                ),
              );
            }).toList(),

            const SizedBox(height: 25),

            Row(
              children: [
                const Text(
                  'Please Upload Required Documents',
                  style: TextStyle(
                    color: AppColors.TextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.TextColor, width: 1.5),
                        ),
                        content: const SizedBox(
                          height: 140,
                          child: Text(
                            'Please merge all required documents into one PDF file and upload it for further processing.',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.TextColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info),
                  color: AppColors.PrimaryColor,
                ),
              ],
            ),

            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => pickFile(true),
              child: documentContainer(
                'Student Documents',
                isChecked: studentFile != null,
                fileName: studentFile?.path.split('/').last,
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => pickFile(false),
              child: documentContainer(
                'Co-Applicant Documents',
                isChecked: coApplicantFile != null,
                fileName: coApplicantFile?.path.split('/').last,
              ),
            ),
            const SizedBox(height: 60),

            AppPrimaryButton(
              title: 'Submit Documents',
              loading: isUploading,
              onPressed: isUploading ? null : uploadDocuments,
            ),
          ],
        ),
      ),
    );
  }

  Widget documentContainer(String title, {bool isChecked = false, String? fileName}) {
    return Container(
      height: fileName != null ? 100 : 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isChecked ? Colors.green : AppColors.PrimaryColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_file_rounded, color: AppColors.TextColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, color: AppColors.TextColor)),
                if (fileName != null)
                  Text(
                    fileName,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_sharp,
            size: 26,
            color: isChecked ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }
}
