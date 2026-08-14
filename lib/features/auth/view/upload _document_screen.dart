import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:payfxglobal/features/auth/viewmodel/kyc_view_model.dart';
import 'package:payfxglobal/features/auth/service/kyc_api_service.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';

import '../../../widgets/profile_created_dialog.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final _formKey = GlobalKey<FormState>();
  late KycViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = KycViewModel(service: kycApiService());
    vm.loadMasterData();
  }

  // =====================================================
  // KYC CONSENT DIALOG
  // =====================================================

  void _showKycConsentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'PAYFX GLOBAL KYC CONSENT',
          style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'By submitting or uploading your PAN Card, Aadhaar Card, Passport, bank statements, address proof, photographs, or any other identity and verification documents (“KYC Documents”) to PayFX Global, you expressly consent to the collection, storage, verification, processing, and use of such information by PayFX Fintech Solutions Private Limited.\n\n'
                  'PayFX Global collects and processes such information in accordance with applicable laws including the Information Technology Act, 2000, and RBI/FEMA guidelines.',
                ),
                SizedBox(height: 16),
                Text('1. PURPOSE OF COLLECTION', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Identity verification, KYC/AML compliance, fraud prevention, and regulatory requirements.'),
                SizedBox(height: 16),
                Text('2. DATA SECURITY', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('PayFX Global implements commercially reasonable security practices to protect your information.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: AppTheme.PrimaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SUBMIT
  // =====================================================

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    final error = vm.validateBeforeSubmit();
    if (error != null) {
      AppSnackbar.show(context, error, success: false);
      return;
    }

    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final rawUserId = args?['user_id'];
      final int userId = rawUserId is int ? rawUserId : int.tryParse(rawUserId?.toString() ?? '') ?? 0;

      final response = await vm.submitKyc(userId: userId);

      if (response['success'] == true) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ProfileCreatedDialog(
            userId: userId,
            onNext: () {
               // After success, we go to login so the user can re-authenticate and refresh the step_no
               Navigator.pushReplacementNamed(context, '/login', arguments: {'user_id': userId});
            }
          ),
        );
      } else {
        AppSnackbar.show(context, response['message'] ?? 'Submission failed', success: false);
      }
    } catch (e) {
      debugPrint('KYC SUBMIT ERROR: $e');
      AppSnackbar.show(context, 'Submission failed', success: false);
    }
  }

  // =====================================================
  // FILE PICKER
  // =====================================================

  String? validateFile(File file) {
    final extension =
    file.path.split('.').last.toLowerCase();

    final sizeInMB =
        file.lengthSync() / (1024 * 1024);

    if (!['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx']
        .contains(extension)) {
      return 'Unsupported file format. Allowed: JPG, PNG, PDF, DOC, DOCX';
    }

    if (['jpg', 'jpeg', 'png'].contains(extension) &&
        sizeInMB > 5) {
      return 'Image size should not exceed 5 MB';
    }

    if (['pdf', 'doc', 'docx'].contains(extension) &&
        sizeInMB > 10) {
      return 'Document size should not exceed 10 MB';
    }

    return null;
  }

  Future<void> _pickImageOrFile(Function(File) onPicked) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.PrimaryColor),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);

                if (Platform.isAndroid) {
                   final camera = await Permission.camera.request();
                   if (!camera.isGranted) {
                     AppSnackbar.show(context, 'Camera permission denied', success: false);
                     return;
                   }
                }
                final picked =
                await ImagePicker().pickImage(source: ImageSource.camera);

                if (picked != null) {
                  final file = File(picked.path);

                  final error = validateFile(file);

                  if (error != null) {
                    AppSnackbar.show(context, error, success: false);
                    return;
                  }

                  onPicked(file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.PrimaryColor),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picked =
                await ImagePicker().pickImage(source: ImageSource.gallery);

                if (picked != null) {
                  final file = File(picked.path);

                  final error = validateFile(file);

                  if (error != null) {
                    AppSnackbar.show(context, error, success: false);
                    return;
                  }

                  onPicked(file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: AppTheme.PrimaryColor),
              title: const Text('File Manager'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                );

                if (result != null && result.files.single.path != null) {
                  final file = File(result.files.single.path!);

                  final error = validateFile(file);

                  if (error != null) {
                    AppSnackbar.show(context, error, success: false);
                    return;
                  }

                  onPicked(file);
                }
                if (result != null && result.files.single.path != null) {
                  onPicked(File(result.files.single.path!));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // UI BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        if (vm.loading) return const Scaffold(body: Center(child: LoadingOverlay()));

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppPrimaryAppBar(
            title: 'KYC Verification',
            onBack: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Question 1 to 5', style: TextStyle(fontFamily: 'Satoshi', fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 24),

                  _buildLabel('Employment Type *'),
                  Row(
                    children: [
                      Radio<int>(value: 1, groupValue: vm.employmentType, activeColor: AppTheme.PrimaryColor, onChanged: (v) => vm.changeEmploymentType(v ?? 1)),
                      const Text('Employed'),
                      const SizedBox(width: 24),
                      Radio<int>(value: 2, groupValue: vm.employmentType, activeColor: AppTheme.PrimaryColor, onChanged: (v) => vm.changeEmploymentType(v ?? 2)),
                      const Text('Self Employed'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (vm.employmentType == 1) ...[
                    _buildDropdownField<String>(
                      label: 'Occupation *',
                      value: vm.selectedOccupation,
                      items: vm.occupationOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: vm.changeOccupation,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(controller: vm.employerController, labelText: 'Employer Name', hintText: 'Enter company name', isRequired: true),
                  ] else ...[
                    _buildLabel('Occupation (Select Any one) *'),
                    const SizedBox(height: 8),
                    _buildRadioList(vm.occupationOptions),
                  ],

                  const SizedBox(height: 24),
                  _buildDropdownField<int>(
                    label: 'Select Source of Fund *',
                    value: vm.selectedSourceOfFundId,
                    items: vm.sourceOfFunds.map((e) => DropdownMenuItem(value: e['id'] as int, child: Text(e['sof_name']?.toString() ?? ''))).toList(),
                    onChanged: vm.changeSourceOfFund,
                  ),

                  const SizedBox(height: 32),
                  _buildLabel('What is your annual income?'),
                  const SizedBox(height: 12),
                  ...vm.annualIncomeOptions.map((e) => Row(
                    children: [
                      Radio<String>(value: e, groupValue: vm.annualIncome, activeColor: AppTheme.PrimaryColor, onChanged: vm.changeAnnualIncome),
                      Text(vm.annualIncomeLabels[e] ?? e),
                    ],
                  )),

                  const SizedBox(height: 32),
                  _buildLabel('Are you a politically exposed person (PEP)?'),
                  const Text('If you don\'t know what this means, it likely doesn\'t apply to you.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Row(
                    children: [
                      Radio<String>(value: 'yes', groupValue: vm.pep, activeColor: AppTheme.PrimaryColor, onChanged: vm.changePep),
                      const Text('Yes'),
                      const SizedBox(width: 32),
                      Radio<String>(value: 'no', groupValue: vm.pep, activeColor: AppTheme.PrimaryColor, onChanged: vm.changePep),
                      const Text('No'),
                    ],
                  ),

                  if (vm.pep == 'yes') ...[
                    const SizedBox(height: 16),
                    AppTextField(controller: vm.pepDetailsController, labelText: 'PEP Details', isRequired: true, hintText: 'Describe role'),
                  ],

                  const SizedBox(height: 40),
                  const Text('Identity Documents', style: TextStyle(fontFamily: 'Satoshi', fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  _buildFileUploadTile(
                    label: 'E-Aadhaar *\n(PDF • Max 10 MB)',
                    file: vm.aadhaarFrontFile,
                    onTap: () => _pickImageOrFile(vm.setAadhaarFront),
                  ),

                  const SizedBox(height: 16),

                  _buildFileUploadTile(
                    label: 'PAN Card (Front Side) *\n(JPG, PNG, PDF • Max 10 MB)',
                    file: vm.panFrontFile,
                    onTap: () => _pickImageOrFile(vm.setPanFront),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24, width: 24, child: Checkbox(value: vm.isAgreed, activeColor: AppTheme.PrimaryColor, onChanged: (v) => vm.changeAgreement(v ?? false))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, color: Colors.black87, fontFamily: 'Satoshi'),
                            children: [
                              const TextSpan(text: 'I acknowledge that I have read and agree to the '),
                              TextSpan(
                                text: 'KYC Consent',
                                style: const TextStyle(color: AppTheme.PrimaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()..onTap = _showKycConsentDialog,
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(color: AppTheme.PrimaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()..onTap = () => ApiService.launchURL('https://www.payfxglobal.com/#privacy'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  AppPrimaryButton(title: 'Submit', loading: vm.submitting, onPressed: vm.submitting ? null : _submitKyc),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600, fontSize: 14));
  }

  Widget _buildDropdownField<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label),
      const SizedBox(height: 8),
      DropdownButtonFormField<T>(
        value: value, items: items, onChanged: onChanged,
        validator: (v) => v == null ? 'Required' : null,
        decoration: InputDecoration(
          filled: true, fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        ),
      ),
    ]);
  }

  Widget _buildRadioList(List<String> options) {
    return Column(
      children: options.map((option) => Row(
        children: [
          Radio<String>(value: option, groupValue: vm.selectedOccupation, activeColor: AppTheme.PrimaryColor, onChanged: vm.changeOccupation, visualDensity: VisualDensity.compact),
          Expanded(child: Text(option, style: const TextStyle(fontSize: 13))),
        ],
      )).toList(),
    );
  }

  Widget _buildFileUploadTile({required String label, required File? file, required VoidCallback onTap}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: file == null ? Colors.grey[300]! : AppTheme.PrimaryColor)),
          child: Row(children: [
            Icon(file == null ? Icons.cloud_upload_outlined : Icons.check_circle, color: file == null ? Colors.grey : AppTheme.PrimaryColor),
            const SizedBox(width: 12),
            Expanded(child: Text(file == null ? 'Tap to upload' : file.path.split('/').last, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    ]);
  }
}
