import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/auth/service/kyc_api_service.dart';
import 'package:payfxglobal/features/auth/viewmodel/kyc_view_model.dart';

class FakeKycApiService extends Fake implements kycApiService {
  @override
  Future<List<Map<String, dynamic>>> getSourceOfFundOptions() async {
    return [
      {'id': 1, 'name': 'Salary'},
      {'id': 2, 'name': 'Business Revenue'},
    ];
  }
}

void main() {
  late FakeKycApiService fakeService;
  late KycViewModel vm;

  setUp(() {
    fakeService = FakeKycApiService();
    vm = KycViewModel(service: fakeService);
  });

  tearDown(() {
    vm.dispose();
  });

  group('KycViewModel Unit Tests', () {
    test('occupationOptions returns list based on employmentType', () {
      vm.employmentType = 1;
      expect(vm.occupationOptions, contains('Public'));
      expect(vm.occupationOptions, contains('Private'));
      expect(vm.occupationOptions, contains('Government Post'));

      vm.changeEmploymentType(2);
      expect(vm.employmentType, 2);
      expect(vm.selectedOccupation, null); // Resets occupation on type change
      expect(
        vm.occupationOptions,
        contains('Doctor / CA / Architect / Lawyer / Consultant'),
      );
      expect(vm.occupationOptions, contains('Student'));
    });

    test('state updates correctly notify listeners and update properties', () {
      vm.changeOccupation('Public');
      expect(vm.selectedOccupation, 'Public');

      vm.changeSourceOfFund(10);
      expect(vm.selectedSourceOfFundId, 10);

      vm.changeAnnualIncome('300000-700000');
      expect(vm.annualIncome, '300000-700000');

      vm.changePep('yes');
      expect(vm.pep, 'yes');

      vm.changeAgreement(true);
      expect(vm.isAgreed, true);
    });

    test('validateBeforeSubmit checks all required fields and file uploads', () {
      // 1. Agreement missing
      expect(vm.validateBeforeSubmit(), 'Please agree to the KYC Consent');

      vm.changeAgreement(true);
      // 2. Aadhaar / PAN files missing
      expect(
        vm.validateBeforeSubmit(),
        'Please upload both Aadhaar Front and PAN Card',
      );

      vm.setAadhaarFront(File('path/to/aadhaar.jpg'));
      vm.setPanFront(File('path/to/pan.jpg'));

      // 3. Occupation missing
      expect(vm.validateBeforeSubmit(), 'Please select your occupation');

      vm.changeOccupation('Public');

      // 4. Source of fund missing
      expect(vm.validateBeforeSubmit(), 'Please select source of fund');

      vm.changeSourceOfFund(1);

      // 5. Income range missing
      expect(vm.validateBeforeSubmit(), 'Please select annual income range');

      vm.changeAnnualIncome('300000-700000');

      // 6. Employer name missing for employmentType == 1
      expect(vm.validateBeforeSubmit(), 'Please enter your employer name');

      vm.employerController.text = 'Acme Corp';

      // 7. All valid
      expect(vm.validateBeforeSubmit(), null);
    });
  });
}
