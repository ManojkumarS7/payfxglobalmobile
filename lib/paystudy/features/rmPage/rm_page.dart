import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:payfxglobal/paystudy/core/constants/app_textfield.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payfxglobal/paystudy/core/constants/dashboard.dart';
import 'package:payfxglobal/paystudy/core/network/api_service.dart';
import 'package:payfxglobal/paystudy/core/constants/app_radio_button.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Model for booking confirmation data
class BookingConfirmation {
  final int scheduleId;
  final String applicantId;
  final String userName;
  final String fullName;
  final String scheduledDate;
  final String scheduledSlot;
  final String assignedUserId;

  BookingConfirmation({
    required this.scheduleId,
    required this.applicantId,
    required this.userName,
    required this.fullName,
    required this.scheduledDate,
    required this.scheduledSlot,
    required this.assignedUserId,
  });

  factory BookingConfirmation.fromJson(Map<String, dynamic> json) {
    return BookingConfirmation(
      scheduleId: json['schedule_id'],
      applicantId: json['applicant_id'].toString(),
      userName: json['user_name'] ?? '',
      fullName: json['full_name'] ?? '',
      scheduledDate: json['scheduled_date'] ?? '',
      scheduledSlot: json['scheduled_slot'] ?? '',
      assignedUserId: json['assigned_user_id'].toString(),
    );
  }
}

class RelationShipManager extends StatefulWidget {
  const RelationShipManager({super.key});

  @override
  State<RelationShipManager> createState() => _RelationShipManagerState();
}

class _RelationShipManagerState extends State<RelationShipManager> {
  late DateTime selectedDate;
  String? selectedTime;
  late TextEditingController loanNumberController = TextEditingController();
  late List<DateTime> dates;
  bool isLoading = true;
  bool isVerifying = false;
  bool isBooking = false;

  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  String? selectedApplicantId;
  String? selectedLoanNo;
  List<dynamic> applications = [];
  int? fxglbUserId;

  static const String loanNoKey = 'loan_ref_no';

  @override
  void initState() {
    super.initState();
    dates = _generateWeekdays(8);
    selectedDate = dates.first;
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
    final number = loanNumberController.text.trim();
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Loan number verified successfully'), backgroundColor: Colors.green),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Invalid loan number');
        }
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isVerifying = false);
    }
  }

  Future<void> _bookSlot() async {
    if (selectedApplicantId == null || selectedApplicantId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an application first.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (selectedTime == null) return;

    setState(() => isBooking = true);

    try {
      final response = await _apiService.post(
        'home/v1/api/store_schedule_call',
        data: FormData.fromMap({
          'ref_applicant_id': selectedApplicantId,
          'selected_date': DateFormat('yyyy-MM-dd').format(selectedDate),
          'selected_slot': selectedTime,
        }),
      );

      if (response.statusCode == 200) {
        var data = response.data;
        if (data is String) data = json.decode(data);

        if (data['status'] == 'success') {
          final confirmation = BookingConfirmation.fromJson(data['data']);
          if (mounted) {
            _showBookingConfirmationSheet(confirmation);
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to book slot');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isBooking = false);
    }
  }

  void _showBookingConfirmationSheet(BookingConfirmation confirmation) {
    String formattedDate = confirmation.scheduledDate;
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(confirmation.scheduledDate);
      formattedDate = DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.TextColor, fontFamily: 'Satoshi'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your appointment has been scheduled successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Satoshi'),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildConfirmationRow(icon: Icons.confirmation_number_outlined, label: 'Booking ID', value: '#${confirmation.scheduleId}', highlight: true),
                  const Divider(height: 24),
                  _buildConfirmationRow(icon: Icons.person_outline, label: 'Name', value: confirmation.fullName.isNotEmpty ? confirmation.fullName : confirmation.userName),
                  const SizedBox(height: 16),
                  _buildConfirmationRow(icon: Icons.calendar_today_outlined, label: 'Date', value: formattedDate),
                  const SizedBox(height: 16),
                  _buildConfirmationRow(icon: Icons.access_time_rounded, label: 'Time Slot', value: confirmation.scheduledSlot),
                  const SizedBox(height: 16),
                  _buildConfirmationRow(icon: Icons.support_agent_rounded, label: 'Manager', value: 'PayStudy Relationship Manager'),
                  const SizedBox(height: 16),
                  _buildConfirmationRow(icon: Icons.timer_outlined, label: 'Duration', value: '30 minutes'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.PrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Satoshi')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationRow({required IconData icon, required String label, required String value, bool highlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.PrimaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Satoshi')),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: highlight ? 16 : 14, fontWeight: highlight ? FontWeight.bold : FontWeight.w600, color: highlight ? AppColors.PrimaryColor : AppColors.TextColor, fontFamily: 'Satoshi')),
            ],
          ),
        ),
      ],
    );
  }

  List<DateTime> _generateWeekdays(int count) {
    List<DateTime> result = [];
    DateTime current = DateTime.now();
    while (result.length < count) {
      if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
        result.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  List<String> _getSlotsForPeriod(String period) {
    List<String> allSlots = [];
    DateTime start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 30);
    DateTime end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 18, 30);
    DateTime now = DateTime.now();
    bool isToday = DateFormat('yyyy-MM-dd').format(selectedDate) == DateFormat('yyyy-MM-dd').format(now);

    while (start.isBefore(end)) {
      DateTime slotEnd = start.add(const Duration(minutes: 30));
      if (!isToday || start.isAfter(now)) {
        String slotText = "${DateFormat('hh:mm a').format(start)} - ${DateFormat('hh:mm a').format(slotEnd)}";
        int hour = start.hour;
        if (period == 'Morning' && hour < 12) {
          allSlots.add(slotText);
        } else if (period == 'Afternoon' && hour >= 12 && hour < 17) {
          allSlots.add(slotText);
        } else if (period == 'Evening' && hour >= 17) {
          allSlots.add(slotText);
        }
      }
      start = slotEnd;
    }
    return allSlots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.TextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Book an Appointment', style: TextStyle(color: AppColors.TextColor, fontSize: 20, fontWeight: FontWeight.w500, fontFamily: 'Satoshi')),
        centerTitle: true,
      ),
      body: isLoading 
          ? const Center(child: CustomLoadingIndicator())
          : (applications.isEmpty ? _NoLoanUI(context) : _MainUI()),
    );
  }

  Widget _MainUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text('Select Application', style: TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.TextColor)),
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
          const Text('Choose a convenient time to speak with our Relationship Manager', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Satoshi')),
          const SizedBox(height: 24),
          _buildProfileCard(),
          const SizedBox(height: 24),
          _buildSectionContainer(
            title: 'Date Selection',
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(selectedDate);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selectedDate = date;
                      selectedTime = null;
                    }),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.PrimaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('E').format(date), style: TextStyle(color: isSelected ? Colors.white : AppColors.TextColor, fontWeight: FontWeight.w500, fontSize: 14)),
                          Text(DateFormat('dd').format(date), style: TextStyle(color: isSelected ? Colors.white : AppColors.TextColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(DateFormat('MMM').format(date), style: TextStyle(color: isSelected ? Colors.white : AppColors.TextColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionContainer(
            title: 'Available Slots',
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeSlotGroup('Morning', _getSlotsForPeriod('Morning')),
                const SizedBox(height: 16),
                _buildTimeSlotGroup('Afternoon', _getSlotsForPeriod('Afternoon')),
                const SizedBox(height: 16),
                _buildTimeSlotGroup('Evening', _getSlotsForPeriod('Evening')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionContainer(
            title: 'Appointment Summary',
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryItem(Icons.calendar_today_outlined, DateFormat('dd MMM yyyy').format(selectedDate)),
                _buildSummaryItem(Icons.access_time, selectedTime ?? 'Not selected'),
                _buildSummaryItem(Icons.person_outline, 'PayStudy Relationship Manager'),
                _buildSummaryItem(Icons.timer_outlined, '30 mins'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (selectedTime == null || isBooking) ? null : _bookSlot,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.PrimaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: AppColors.PrimaryColor!, width: 2)),
              ),
              child: const Text('Confirm Slot', style: TextStyle(fontSize: 18, fontFamily: 'Satoshi', fontWeight: FontWeight.w500, color: AppColors.TextColor)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
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
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.TextColor, width: 1.2)),
            child: const Text(
              'Please first check and confirm your eligibility. '
              'Once your eligibility is confirmed, you can talk with our Relationship Manager.',
              style: TextStyle(fontSize: 16, fontFamily: 'Satoshi', fontWeight: FontWeight.w500, color: AppColors.TextColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 50),
          // SizedBox(
          //   height: 50,
          //   width: double.infinity,
          //   child: OutlinedButton(
          //     onPressed: _showLoanPopup,
          //     style: OutlinedButton.styleFrom(
          //       side: BorderSide(color: AppColors.PrimaryColor!, width: 1.5),
          //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          //     ),
          //     child: const Text('Check Eligibility', style: TextStyle(fontSize: 18, fontFamily: 'Satoshi', fontWeight: FontWeight.w500, color: AppColors.TextColor)),
          //   ),
          // ),
          AppPrimaryButton(title: 'Check Eligibility',onPressed: () => Navigator.of(context).pop(), )
        ],
      ),
    );
  }

  void _showLoanPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter Your Loan Number', style: TextStyle(color: AppColors.TextColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Satoshi')),
                const SizedBox(height: 24),
                AppTextField(controller: loanNumberController, labelText: 'Loan Number', hintText: 'eg: LOAN-REF-2026-0001'),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  title: 'Verify',
                  onPressed: isVerifying ? null : () async {
                    setDialogState(() => isVerifying = true);
                    await _verifyLoanNumber();
                    if (mounted) setDialogState(() => isVerifying = false);
                  },
                ),
                const SizedBox(height: 20),
                const Text('If you have no loan go back to check your eligibility', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontFamily: 'Satoshi', fontWeight: FontWeight.w500, color: AppColors.TextColor)),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  title: 'Check Eligibility',
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainDashboard()), (route) => false);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE8EAF6), child: Text('P', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.PrimaryColor))),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PayStudy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.TextColor)),
                  Text('Relationship Manager', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: Colors.grey, size: 18),
                  SizedBox(width: 4),
                  Text('Available on weekdays', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.TextColor))),
          child,
        ],
      ),
    );
  }

  Widget _buildTimeSlotGroup(String label, List<String> slots) {
    if (slots.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.TextColor, fontFamily: 'Satoshi')),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: slots.map((slot) {
            final isSelected = selectedTime == slot;
            return GestureDetector(
              onTap: () => setState(() => selectedTime = slot),
              child: SizedBox(
                width: (MediaQuery.of(context).size.width - 100) / 3,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: isSelected ? AppColors.PrimaryColor : const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
                  child: Text(slot.split(' ')[0], style: TextStyle(color: isSelected ? Colors.white : AppColors.TextColor, fontWeight: FontWeight.w500, fontSize: 12)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.TextColor)),
        ],
      ),
    );
  }
}
