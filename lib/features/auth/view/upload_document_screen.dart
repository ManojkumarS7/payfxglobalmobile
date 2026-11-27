import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:payfxglobal/utils/external_activity_service.dart';
import 'package:payfxglobal/features/auth/viewmodel/kyc_view_model.dart';
import 'package:payfxglobal/features/auth/service/kyc_api_service.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/registration_progress_widget.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/profile_created_dialog.dart';

class UploadDocumentsScreen extends ConsumerStatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  ConsumerState<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends ConsumerState<UploadDocumentsScreen> {
  final _formKey = GlobalKey<FormState>();
  late KycViewModel vm;

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    vm = KycViewModel(service: kycApiService());
    vm.loadMasterData();
  }

  void _showKycConsentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('KYC Consent', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800)),
        content: const SingleChildScrollView(
          child: Text(
            'By submitting your documents, you consent to the collection and processing of your personal information by PayFX Global for identity verification and regulatory compliance purposes as per RBI/FEMA guidelines.',
            style: TextStyle(fontFamily: _font, height: 1.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: _navy))),
        ],
      ),
    );
  }

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
        final rawData = response['data'];
        Map<String, dynamic> userData = {};
        if (rawData is Map) userData = Map<String, dynamic>.from(rawData);
        if (userData.isNotEmpty) await UserStorage.saveUserData(userData);

        await StepCompletionOverlay.show(context, 5);
        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ProfileCreatedDialog(
            userId: userId,
            userData: userData,
            onNext: () => Navigator.pushReplacementNamed(context, '/login', arguments: {'user_id': userId}),
          ),
        );
      } else {
        AppSnackbar.show(context, response['message'] ?? 'Submission failed', success: false);
      }
    } catch (e) {
      AppSnackbar.show(context, 'Submission failed', success: false);
    }
  }

  Future<void> _pickImageOrFile(Function(File) onPicked) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SafeArea(
          child: Wrap(
            children: [
              _pickOption(Icons.camera_alt_rounded, 'Camera', () async {
                if (Platform.isAndroid) {
                  final status = await Permission.camera.request();
                  if (!status.isGranted) return;
                }
                final picked = await ExternalActivityService.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (picked != null) onPicked(File(picked.path));
                if (mounted) Navigator.pop(context);
              }),
              _pickOption(Icons.photo_library_rounded, 'Gallery', () async {
                final picked = await ExternalActivityService.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (picked != null) onPicked(File(picked.path));
                if (mounted) Navigator.pop(context);
              }),
              _pickOption(Icons.insert_drive_file_rounded, 'Documents', () async {
                final result = await ExternalActivityService.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
                if (result != null && result.files.single.path != null) onPicked(File(result.files.single.path!));
                if (mounted) Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickOption(IconData icon, String label, VoidCallback onTap) => ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _navy)),
        title: Text(label, style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w700)),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        if (vm.loading) return const Scaffold(backgroundColor: _bg, body: Center(child: CustomLoadingIndicator()));

        int i = 0;
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            final exit = await SaveProgressBanner.showExitConfirmation(context);
            if (exit && mounted) Navigator.pushReplacementNamed(context, '/login');
          },
          child: Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              backgroundColor: _bg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
                onPressed: () async {
                  final exit = await SaveProgressBanner.showExitConfirmation(context);
                  if (exit && mounted) Navigator.pushReplacementNamed(context, '/login');
                },
              ),
              title: const Text('KYC Verification', style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5)),
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RegistrationProgressHeader(currentStep: 5),
                    const SizedBox(height: 12),
                    const SocialProofBadge(),
                    const SizedBox(height: 16),
                    _FadeSlide(index: i++, child: const Text('Employment & Income', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
                    const SizedBox(height: 12),
                    _FadeSlide(
                      index: i++,
                      child: _buildWhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Employment Type *', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildRadioTile('Employed', 1, vm.employmentType, (v) => vm.changeEmploymentType(v!)),
                                const SizedBox(width: 16),
                                _buildRadioTile('Self Employed', 2, vm.employmentType, (v) => vm.changeEmploymentType(v!)),
                              ],
                            ),
                            const SizedBox(height: 20),
                          if (vm.employmentType == 1) ...[
                            _buildDropdownField<String>(
                              label: 'Occupation *',
                              value: vm.selectedOccupation,
                              items: vm.occupationOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: vm.changeOccupation,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(controller: vm.employerController, labelText: 'Employer Name', isRequired: true),
                          ] else ...[
                            const Text('Occupation *', style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            _buildRadioGrid(vm.occupationOptions),
                          ],
                          const SizedBox(height: 20),
                          _buildDropdownField<int>(
                            label: 'Source of Fund *',
                            value: vm.selectedSourceOfFundId,
                            items: vm.sourceOfFunds.map((e) => DropdownMenuItem(value: e['id'] as int, child: Text(e['sof_name'] ?? ''))).toList(),
                            onChanged: vm.changeSourceOfFund,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FadeSlide(index: i++, child: const Text('Annual Income', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
                  const SizedBox(height: 12),
                  _FadeSlide(
                    index: i++,
                    child: _buildWhiteCard(
                      child: Column(
                        children: vm.annualIncomeOptions.map((e) => _buildRadioRow(vm.annualIncomeLabels[e] ?? e, e, vm.annualIncome, vm.changeAnnualIncome)).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FadeSlide(index: i++, child: const Text('Regulatory Details', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
                  const SizedBox(height: 12),
                  _FadeSlide(
                    index: i++,
                    child: _buildWhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Are you a politically exposed person (PEP)?', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                          const SizedBox(height: 4),
                          Text('Public officials, their family or close associates.', style: TextStyle(fontFamily: _font, fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildRadioTile('Yes', 'yes', vm.pep, vm.changePep),
                              const SizedBox(width: 16),
                              _buildRadioTile('No', 'no', vm.pep, vm.changePep),
                            ],
                          ),
                          if (vm.pep == 'yes') ...[
                            const SizedBox(height: 20),
                            AppTextField(controller: vm.pepDetailsController, labelText: 'PEP Details', isRequired: true, hintText: 'Describe your role'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FadeSlide(index: i++, child: const Text('Identity Documents', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
                  const SizedBox(height: 12),
                  _FadeSlide(
                    index: i++,
                    child: _buildWhiteCard(
                      child: Column(
                        children: [
                          _buildFileUploadTile(label: 'Aadhaar (PDF • Max 10MB) *', file: vm.aadhaarFrontFile, onTap: () => _pickImageOrFile(vm.setAadhaarFront)),
                          const SizedBox(height: 16),
                          _buildFileUploadTile(label: 'PAN Card Front (PDF/JPG • Max 10MB) *', file: vm.panFrontFile, onTap: () => _pickImageOrFile(vm.setPanFront)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FadeSlide(
                    index: i++,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24, width: 24, child: Checkbox(value: vm.isAgreed, activeColor: _navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), onChanged: (v) => vm.changeAgreement(v ?? false))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontFamily: _font, fontSize: 13, color: Colors.grey.shade600, height: 1.5, fontWeight: FontWeight.w600),
                              children: [
                                const TextSpan(text: 'I acknowledge that I have read and agree to the '),
                                TextSpan(text: 'KYC Consent', style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = _showKycConsentDialog),
                                const TextSpan(text: ' and '),
                                TextSpan(text: 'Privacy Policy', style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = () => ApiService.launchURL('https://www.payfxglobal.com/#privacy')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _FadeSlide(
                    index: i++,
                    child: _Pressable(
                      onTap: vm.submitting ? null : _submitKyc,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                        child: vm.submitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Submit KYC', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  }

  Widget _buildWhiteCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))]),
        child: child,
      );

  Widget _buildRadioTile<T>(String label, T value, T? group, Function(T?) onChanged) {
    final selected = group == value;
    return Expanded(
      child: _Pressable(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _navy.withOpacity(0.08) : _bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _navy : Colors.transparent, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: selected ? _navy : Colors.grey.shade600)),
        ),
      ),
    );
  }

  Widget _buildRadioRow<T>(String label, T value, T? group, Function(T?) onChanged) {
    final selected = group == value;
    return _Pressable(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: selected ? _navy.withOpacity(0.05) : _bg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? _navy : _ink))),
            Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: selected ? _navy : Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioGrid(List<String> options) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final selected = vm.selectedOccupation == option;
        return _Pressable(
          onTap: () => vm.changeOccupation(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _navy.withOpacity(0.08) : _bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? _navy : Colors.transparent, width: 1),
            ),
            child: Text(option, style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? _navy : Colors.grey.shade700)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdownField<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(16)),
        child: DropdownButtonFormField<T>(
          dropdownColor: Colors.white,
          value: value,
          items: items,
          onChanged: onChanged,
          validator: (v) => v == null ? 'Required' : null,
          style: const TextStyle(fontFamily: _font, fontSize: 15, color: _ink, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16), border: InputBorder.none),
        ),
      ),
    ]);
  }

  Widget _buildFileUploadTile({required String label, required File? file, required VoidCallback onTap}) {
    final bool hasFile = file != null;
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFE5F8E0) : _bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: hasFile ? const Color(0xFFBFEAB8) : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Icon(hasFile ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, color: hasFile ? const Color(0xFF0F7B4F) : _navy, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
                  if (hasFile) Text(file.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _font, fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _FadeSlide extends StatelessWidget {
  final Widget child;
  final int index;
  const _FadeSlide({required this.child, this.index = 0});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, this.onTap});
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
