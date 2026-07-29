import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payfxglobal/paystudy/core/constants/app_textfield.dart';
import 'package:payfxglobal/paystudy/core/constants/app_radio_button.dart';
import 'package:payfxglobal/paystudy/core/network/api_service.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/custom_button.dart';

class ApplicationProcess extends StatefulWidget {
  const ApplicationProcess({super.key});

  @override
  State<ApplicationProcess> createState() => _ApplicationProcessState();
}

class _ApplicationProcessState extends State<ApplicationProcess> {
  static const String loanNoKey = 'loan_ref_no';
  String? selectedLoanNo;
  String? selectedApplicantId;
  final TextEditingController _loanNumberController = TextEditingController();
  bool isLoading = true;
  bool isVerifying = false;
  final ApiService _apiService = ApiService();
  int? loanStatus;
  String? studentName;
  String? loanDate;
  final _storage = const FlutterSecureStorage();
  List<dynamic> applications = [];
  int? fxglbUserId;

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
    if (fxglbUserId == null) return;
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
      if (selectedLoanNo != null) {
        await _fetchLoanStatus(selectedLoanNo!);
      }
    } else if (savedLoanNo != null) {
      selectedLoanNo = savedLoanNo;
      await _fetchLoanStatus(savedLoanNo);
    } else if (applications.isNotEmpty) {
      final firstApp = applications.first;
      selectedApplicantId = firstApp['applicant_id'].toString();
      selectedLoanNo = firstApp['loan_ref_no']?.toString();
      if (selectedLoanNo != null) {
        await _fetchLoanStatus(selectedLoanNo!);
        await _persistSelection(selectedLoanNo!, selectedApplicantId!);
      }
    }
  }

  Future<void> _persistSelection(String loanNo, String applicantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(loanNoKey, loanNo);
    await _storage.write(key: 'selected_applicant_id', value: applicantId);
  }

  Future<void> _fetchLoanStatus(String loanNo) async {
    try {
      final response = await _apiService.post(
        'home/v1/api/loan_check_status',
        data: FormData.fromMap({'loan_number': loanNo}),
      );

      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) data = json.decode(data);

        if (data['status'] == 'success') {
          final details = data['data'] ?? data;
          _updateLocalStatus(details);
        }
      }
    } catch (e) {
      debugPrint('Fetch loan status error: $e');
    }
  }

  void _updateLocalStatus(dynamic details) {
    final statusIdStr = details['status_id']?.toString() ?? details['loan_status']?.toString();
    final statusId = statusIdStr != null ? int.tryParse(statusIdStr) : null;
    final name = details['applicant_name']?.toString() ?? details['full_name']?.toString();
    final date = details['loan_date']?.toString();

    if (statusId != null) {
      _storage.write(key: 'loan_status', value: statusId.toString());
    }

    setState(() {
      loanStatus = statusId;
      if (name != null) studentName = name;
      loanDate = (date != null && date != 'null' && date.isNotEmpty) ? date : null;
    });
  }

  Future<void> _onApplicationSelected(dynamic app) async {
    final loanNo = app['loan_ref_no']?.toString();
    final applicantId = app['applicant_id']?.toString();

    if (loanNo != null && applicantId != null) {
      setState(() {
        selectedLoanNo = loanNo;
        selectedApplicantId = applicantId;
        studentName = app['applicant_name']?.toString();
        isLoading = true;
      });
      await _persistSelection(loanNo, applicantId);
      await _fetchLoanStatus(loanNo);
      setState(() => isLoading = false);
    }
  }

  final List<String> timelineTitles = [
    "Check Eligibility",
    "Discussion in Progress",
    "Pending Document",
    "Logged in",
    "Sanctioned",
    "Hold",
    "Disbursement",
  ];

  int _getStatusIndex(int? statusId) {
    if (statusId == null) return 0;
    switch (statusId) {
      case 0: return 1; // Explicitly map 0 to Discussion in Progress as per user request
      case 4: return 0; // Enquiry
      case 1: return 1; // Discussion
      case 6: return 2; // Pending Doc
      case 8: return 3; // Logged In
      case 3: return 4; // Sanctioned
      case 13: return 5; // Hold
      case 12: return 6; // Disbursement
      default: return 0;
    }
  }

  void _showUpdatePopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Application Update',
          style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Discussion in Progress',
          style: TextStyle(fontFamily: 'Satoshi', fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.PrimaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.TextColor),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Application Process',
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
          : (applications.isEmpty ? _NoLoanUI(context) : _LoanTimelineUI()),
    );
  }

  Widget _NoLoanUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
              'Please first check and confirm your eligibility. '
              'Once your eligibility is confirmed, you can see the application status.',
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
          AppPrimaryButton(title: 'Check Eligibility', onPressed: () => Navigator.of(context).pop())
        ],
      ),
    );
  }

  Widget _LoanTimelineUI() {
    int currentStatusIndex = _getStatusIndex(loanStatus);
    
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
                child: AppRadioTile<String?>(
                  groupValue: selectedApplicantId,
                  title: app['applicant_name']?.toString() ?? "Active Application",
                  value: appId,
                  subtitle: appLoanNo,
                  onChanged: (val) => _onApplicationSelected(app),
                ),
              );
            }).toList(),

            const SizedBox(height: 25),

            if (studentName != null) ...[
               Text(
                'Status for : $studentName',
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.TextColor,
                ),
              ),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(timelineTitles.length, (index) {
                bool isCompleted = index <= currentStatusIndex;
                // Show date if this step is the current status
                String? stepDate = (index == currentStatusIndex) ? loanDate : null;

                return TimelineStep(
                  number: index + 1,
                  title: timelineTitles[index],
                  isLast: index == timelineTitles.length - 1,
                  isCompleted: isCompleted,
                  date: stepDate,
                  onViewUpdate: _showUpdatePopup,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class TimelineStep extends StatelessWidget {
  final int number;
  final String title;
  final bool isLast;
  final bool isCompleted;
  final String? date;
  final VoidCallback? onViewUpdate;

  const TimelineStep({
    super.key,
    required this.number,
    required this.title,
    required this.isLast,
    this.isCompleted = false,
    this.date,
    this.onViewUpdate,
  });

  @override
  Widget build(BuildContext context) {
    Color stepColor = isCompleted ? AppColors.PrimaryColor : Colors.grey;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: stepColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isLast) Container(width: 2, height: 40, color: stepColor),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isCompleted ? AppColors.TextColor : Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                if (isCompleted)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onViewUpdate,
                        child: const Text(
                          'View Update',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w500,
                            color: AppColors.PrimaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      // const SizedBox(width: 30),
                      // Text(
                      //   date ?? 'Date',
                      //   style: const TextStyle(
                      //     fontSize: 14,
                      //     fontFamily: 'Satoshi',
                      //     fontWeight: FontWeight.w500,
                      //     color: AppColors.PrimaryColor,
                      //   ),
                      // ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
