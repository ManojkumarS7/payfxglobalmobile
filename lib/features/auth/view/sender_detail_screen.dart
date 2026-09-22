import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:payfxglobal/features/auth/viewmodel/sender_view_model.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';

class SenderDetailsScreen extends StatefulWidget {
  final String? previousPage;
  const SenderDetailsScreen({super.key, this.previousPage});

  @override
  State<SenderDetailsScreen> createState() => _SenderDetailsScreenState();
}

class _SenderDetailsScreenState extends State<SenderDetailsScreen> {


  late SenderDetailsViewModel vm;

  @override
  void initState() {
    super.initState();

    vm = SenderDetailsViewModel(
      apiService: AuthApiService(),
    );

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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Access Restricted'),
        content: const Text('You will not allowed transaction if you have not resided in India for more than 180 days.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.PrimaryColor, fontWeight: FontWeight.bold)),
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
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppPrimaryAppBar(
              title: 'Sender Details',
              onBack: () => Navigator.pushReplacementNamed(context, '/login'),
            ),

            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  child: Form(
                    key: vm.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Complete your profile', style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 24,
                            fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text(
                            'Please verify and complete details fetched from PAN card.',
                            style: TextStyle(fontFamily: 'Satoshi',
                                fontSize: 14,
                                color: Colors.black54)),
                        const SizedBox(height: 32),
                        AppTextField(controller: vm.firstNameController,
                            labelText: 'First Name',
                            isRequired: true,
                            enabled: false),
                        const SizedBox(height: 16),
                        AppTextField(controller: vm.lastNameController,
                            labelText: 'Last Name',
                            isRequired: true,
                            enabled: false),
                        const SizedBox(height: 16),
                        AppTextField(controller: vm.dobController,
                            labelText: 'Date of Birth',
                            isRequired: true,
                            enabled: false,
                            hintText: 'DD-MM-YYYY'),
                        const SizedBox(height: 16),
                        AppTextField(
                            controller: TextEditingController(text: 'India'),
                            labelText: 'Country',
                            enabled: false),
                        const SizedBox(height: 16),
                        _buildStateDropdown(),
                        const SizedBox(height: 16),
                        AppTextField(controller: vm.streetController,
                            labelText: 'Street Address',
                            isRequired: true,
                            hintText: 'Enter street name'),
                        const SizedBox(height: 16),
                        AppTextField(controller: vm.apartmentController,
                            labelText: 'Apartment/Suite No',
                            hintText: 'Optional'),
                        const SizedBox(height: 16),
                        AppTextField(controller: vm.cityController,
                            labelText: 'City',
                            isRequired: true,
                            hintText: 'Enter city'),
                        const SizedBox(height: 16),
                        AppTextField(controller: vm.postalController,
                            labelText: 'Postal Code',
                            isRequired: true,
                            keyboardType: TextInputType.number,
                            hintText: 'Enter PIN code'),
                        const SizedBox(height: 16),
                        _buildPhoneField(),
                        const SizedBox(height: 24),
                        _buildGender(),
                        const SizedBox(height: 24),
                        _buildResidencyQuestion(),
                        const SizedBox(height: 40),
                        AppPrimaryButton(title: 'Continue',
                          onPressed: vm.isButtonEnabled && !vm.isLoading
                              ? _submit
                              : null,
                          loading: vm.isLoading,),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                if (vm.isLoading) const LoadingOverlay(),
              ],
            ),
          );
        }

    );
  }

  Widget _buildResidencyQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Have you resided in India for more than 180 days? *',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Radio<int>(
              value: 1,
              groupValue: vm.resided180Days,
              activeColor: AppTheme.PrimaryColor,
              onChanged: (value) => vm.updateResidencyStatus(value),
            ),
            const Text('Yes', style: TextStyle(fontFamily: 'Satoshi')),
            const SizedBox(width: 32),
            Radio<int>(
              value: 0,
              groupValue: vm.resided180Days,
              activeColor: AppTheme.PrimaryColor,
              onChanged: (value) {
                vm.updateResidencyStatus(value);
                _showResidencyAlert();
              },
            ),
            const Text('No', style: TextStyle(fontFamily: 'Satoshi')),
          ],
        ),
      ],
    );
  }

  Widget _buildGender() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your gender *',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Radio<String>(
              value: 'Male',
              groupValue: vm.gender,
              activeColor: AppTheme.PrimaryColor,
              onChanged: (value) => vm.updateGender(value),
            ),
            const Text('Male', style: TextStyle(fontFamily: 'Satoshi')),
            const SizedBox(width: 32),
            Radio<String>(
              value: 'Female',
              groupValue: vm.gender,
              activeColor: AppTheme.PrimaryColor,
              onChanged: (value) {
                vm.updateGender(value);
              },
            ),
            const Text('Female', style: TextStyle(fontFamily: 'Satoshi')),
            const SizedBox(width: 32),
            Radio<String>(
              value: 'Others',
              groupValue: vm.gender,
              activeColor: AppTheme.PrimaryColor,
              onChanged: (value) {
                vm.updateGender(value);
              },
            ),
            const Text('Others', style: TextStyle(fontFamily: 'Satoshi')),
          ],
        ),
      ],
    );
  }



  Widget _buildStateDropdown() {
    return DropdownSearch<Map<String, dynamic>>(
      items: vm.states,
      itemAsString: (item) => item['name'] ?? '',

      selectedItem: vm.states.firstWhere(
            (e) => e['id'] == vm.selectedStateId,
        orElse: () => {},
      ),

      popupProps: PopupProps.menu(
        showSearchBox: true,


        menuProps: const MenuProps(
          backgroundColor: Colors.white,
        ),


        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            focusColor: AppTheme.PrimaryColor,
            hoverColor: AppTheme.PrimaryColor,

            hintText: 'Search state',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        itemBuilder: (context, item, isSelected) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Text(
              item['name'],
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),

      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'State *',
          labelStyle: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.TextColor.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.PrimaryColor,
            ),
          ),
        ),
      ),

      onChanged: (value) {
        setState(() {
          vm.selectedStateId = value?['id'];
        });

        vm.validateForm();
      },

      validator: (value) {
        if (value == null) {
          return 'State is required';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return IntlPhoneField(
      controller: vm.mobileController, 
      initialCountryCode: 'IN',
      onChanged: (phone) => vm.updatePhoneNumber(phone.completeNumber),
      decoration: InputDecoration(
        labelText: 'Mobile Number *', labelStyle: TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.TextColor.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.PrimaryColor)),
        counterText: '',
      ),
    );
  }

  Future<void> _submit() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final userId = args?['user_id'];

    if (userId == null) return;

    final result = await vm.submitSenderDetails(
      userId: int.parse(userId.toString()),
    );

    if (result['success'] == true) {
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/upload-documents',
        arguments: {
          'user_id': userId,
        },
      );
    } else {
      final message = vm.formatApiError(
        result['message'] ?? 'Failed to save details',
      );

      if (!mounted) return;

      print(message);
      AppSnackbar.show(
        context,
        message,
        success: false,
      );
    }
  }
}
