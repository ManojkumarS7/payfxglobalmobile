import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:payfxglobal/features/auth/viewmodel/sender_view_model.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';

import '../../../utils/app_theme.dart';

class SenderDetailsScreen extends StatefulWidget {
  final String? previousPage;
  const SenderDetailsScreen({super.key, this.previousPage});

  @override
  State<SenderDetailsScreen> createState() => _SenderDetailsScreenState();
}

class _SenderDetailsScreenState extends State<SenderDetailsScreen> {
  late SenderDetailsViewModel vm;

  // ---- Palette (Matched with Dashboard) ----
  // static const Color _navy = Color(0xFF16305C);
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    vm = SenderDetailsViewModel(apiService: AuthApiService());
    vm.initListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      vm.fillPanDetails(args);
      vm.loadStates(args);
    });
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  void _showResidencyAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Access Restricted', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800)),
        content: const Text('Access to international transfers is restricted for individuals residing in India for less than 180 days.', 
            style: TextStyle(fontFamily: _font, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color:  AppTheme.PrimaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, child) {
        int i = 0;
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
            title: const Text(
              'Profile Details',
              style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Form(
                  key: vm.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FadeSlide(index: i++, child: const Text('Personal Information', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
                      const SizedBox(height: 12),
                      _FadeSlide(
                        index: i++,
                        child: _buildWhiteCard(
                          child: Column(
                            children: [
                              AppTextField(controller: vm.firstNameController, labelText: 'First Name', isRequired: true),
                              const SizedBox(height: 16),
                              AppTextField(controller: vm.lastNameController, labelText: 'Last Name', isRequired: true),
                              const SizedBox(height: 16),
                              AppTextField(controller: vm.dobController, labelText: 'Date of Birth', isRequired: true, enabled: false, hintText: 'DD-MM-YYYY'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _FadeSlide(index: i++, child: const Text('Address Details', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
                      const SizedBox(height: 12),
                      _FadeSlide(
                        index: i++,
                        child: _buildWhiteCard(
                          child: Column(
                            children: [
                              AppTextField(controller: TextEditingController(text: 'India'), labelText: 'Country', enabled: false),
                              const SizedBox(height: 16),
                              _buildStateDropdown(),
                              const SizedBox(height: 16),
                              AppTextField(controller: vm.streetController, labelText: 'Street Address', isRequired: true, hintText: 'Enter street name'),
                              const SizedBox(height: 16),
                              AppTextField(controller: vm.apartmentController, labelText: 'Apartment/Suite No', hintText: 'Optional'),
                              const SizedBox(height: 16),
                              AppTextField(controller: vm.cityController, labelText: 'City', isRequired: true, hintText: 'Enter city'),
                              const SizedBox(height: 16),
                              AppTextField(controller: vm.postalController, labelText: 'Postal Code', isRequired: true, keyboardType: TextInputType.number, hintText: 'Enter PIN code'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _FadeSlide(index: i++, child: const Text('Contact & Other Details', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
                      const SizedBox(height: 12),
                      _FadeSlide(
                        index: i++,
                        child: _buildWhiteCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPhoneField(),
                              const SizedBox(height: 24),
                              _buildGender(),
                              const SizedBox(height: 24),
                              _buildResidencyQuestion(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _FadeSlide(
                        index: i++,
                        child: _Pressable(
                          onTap: vm.isButtonEnabled && !vm.isLoading ? _submit : null,
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: vm.isButtonEnabled ?  AppTheme.PrimaryColor : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: vm.isButtonEnabled ? [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))] : [],
                            ),
                            child: vm.isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('Complete Profile', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              if (vm.isLoading) const LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWhiteCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))]),
        child: child,
      );

  Widget _buildResidencyQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Have you resided in India for more than 180 days? *', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildRadioTile('Yes', 1, vm.resided180Days, (v) => vm.updateResidencyStatus(v)),
            const SizedBox(width: 16),
            _buildRadioTile('No', 0, vm.resided180Days, (v) {
              vm.updateResidencyStatus(v);
              _showResidencyAlert();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildGender() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select your gender *', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildRadioTile('Male', 'Male', vm.gender, (v) => vm.updateGender(v)),
            const SizedBox(width: 10),
            _buildRadioTile('Female', 'Female', vm.gender, (v) => vm.updateGender(v)),
            const SizedBox(width: 10),
            _buildRadioTile('Others', 'Others', vm.gender, (v) => vm.updateGender(v)),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioTile<T>(String label, T value, T? group, Function(T?) onChanged) {
    final selected = group == value;
    return Expanded(
      child: _Pressable(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ?  AppTheme.PrimaryColor.withOpacity(0.08) : _bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ?  AppTheme.PrimaryColor : Colors.transparent, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: selected ?  AppTheme.PrimaryColor : Colors.grey.shade600)),
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return DropdownSearch<Map<String, dynamic>>(
      items: vm.states,
      itemAsString: (item) => item['name'] ?? '',
      selectedItem: vm.states.firstWhere((e) => e['id'] == vm.selectedStateId, orElse: () => {}),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        menuProps: const MenuProps(backgroundColor: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search state...',
            prefixIcon: const Icon(Icons.search_rounded, color:  AppTheme.PrimaryColor),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        itemBuilder: (context, item, isSelected) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Text(item['name'], style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ?  AppTheme.PrimaryColor : _ink)),
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'State *',
          labelStyle: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: Colors.grey.shade500),
          filled: true,
          fillColor: _bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _accent, width: 2)),
        ),
      ),
      onChanged: (value) {
        setState(() => vm.selectedStateId = value?['id']);
        vm.validateForm();
      },
    );
  }

  Widget _buildPhoneField() {
    return IntlPhoneField(
      controller: vm.mobileController,
      initialCountryCode: 'IN',
      onChanged: (phone) => vm.updatePhoneNumber(phone.completeNumber),
      style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w700, color: _ink),
      decoration: InputDecoration(
        labelText: 'Mobile Number *',
        labelStyle: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: Colors.grey.shade500),
        filled: true,
        fillColor: _bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _accent, width: 2)),
        counterText: '',
      ),
    );
  }

  Future<void> _submit() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final userId = args?['user_id'];
    if (userId == null) return;

    final result = await vm.submitSenderDetails(userId: int.parse(userId.toString()));
    if (result['success'] == true) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/upload-documents', arguments: {'user_id': userId});
    } else {
      final message = vm.formatApiError(result['message'] ?? 'Failed to save details');
      if (mounted) AppSnackbar.show(context, message, success: false);
    }
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black.withOpacity(0.2), child: const Center(child: CustomLoadingIndicator()));
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
