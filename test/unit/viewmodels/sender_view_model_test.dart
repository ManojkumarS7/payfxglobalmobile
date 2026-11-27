import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/auth/service/auth_api_service.dart';
import 'package:payfxglobal/features/auth/viewmodel/sender_view_model.dart';

class FakeAuthApiService extends Fake implements AuthApiService {
  List<Map<String, dynamic>> statesResponse = [
    {'id': 1, 'name': 'Maharashtra'},
    {'id': 2, 'name': 'Karnataka'},
    {'id': 3, 'name': 'Delhi'},
  ];

  Map<String, dynamic> saveSenderDetailsResponse = {
    'success': true,
    'message': 'Sender details saved',
  };

  @override
  Future<List<Map<String, dynamic>>> getStates() async {
    return statesResponse;
  }

  @override
  Future<Map<String, dynamic>> saveSenderDetails({
    required int userId,
    required String firstName,
    required String lastName,
    required String dob,
    required String street,
    required String apartment,
    required String city,
    required String postal,
    required String mobile,
    required int stateId,
    required int resident180Days,
    required String gender,
  }) async {
    return saveSenderDetailsResponse;
  }
}

void main() {
  late FakeAuthApiService fakeApiService;
  late SenderDetailsViewModel vm;

  setUp(() {
    fakeApiService = FakeAuthApiService();
    vm = SenderDetailsViewModel(apiService: fakeApiService);
  });

  tearDown(() {
    vm.dispose();
  });

  group('SenderDetailsViewModel Unit Tests', () {
    test('fillPanDetails correctly populates names and address fields', () {
      final panData = {
        'name': 'John Michael Doe',
        'dob': '1990-01-01',
        'address': {
          'street': '123 Main St',
          'line2': 'Apt 4B',
          'city': 'Mumbai',
          'pincode': '400001',
        },
      };

      vm.fillPanDetails(panData);

      expect(vm.firstNameController.text, 'John');
      expect(vm.lastNameController.text, 'Michael Doe');
      expect(vm.dobController.text, '1990-01-01');
      expect(vm.streetController.text, '123 Main St');
      expect(vm.apartmentController.text, 'Apt 4B');
      expect(vm.cityController.text, 'Mumbai');
      expect(vm.postalController.text, '400001');
    });

    test('fillPanDetails handles single-word name', () {
      final panData = {
        'name': 'Cher',
        'dob': '1980-05-05',
      };

      vm.fillPanDetails(panData);

      expect(vm.firstNameController.text, 'Cher');
      expect(vm.lastNameController.text, '');
    });

    test('validateForm checks mandatory fields, Indian phone number, and residency', () {
      expect(vm.isButtonEnabled, false);

      vm.firstNameController.text = 'Rahul';
      vm.lastNameController.text = 'Sharma';
      vm.dobController.text = '1995-08-15';
      vm.streetController.text = 'MG Road';
      vm.cityController.text = 'Bengaluru';
      vm.postalController.text = '560001';
      vm.mobileController.text = '9876543210'; // Valid Indian phone number
      vm.selectedStateId = 2;
      vm.resided180Days = 1;

      vm.validateForm();
      expect(vm.isButtonEnabled, true);

      // Invalid phone number
      vm.mobileController.text = '12345';
      vm.validateForm();
      expect(vm.isButtonEnabled, false);

      // Not resident for 180 days
      vm.mobileController.text = '9876543210';
      vm.resided180Days = 0;
      vm.validateForm();
      expect(vm.isButtonEnabled, false);
    });

    test('loadStates matches state name from arguments', () async {
      final args = {
        'address': {'state': 'karnataka'},
      };

      await vm.loadStates(args);

      expect(vm.states.length, 3);
      expect(vm.selectedStateId, 2); // Karnataka ID
    });

    test('formatApiError maps database exception codes to user-friendly messages', () {
      expect(
        vm.formatApiError('SQLSTATE[23000]: Duplicate entry uq_pan'),
        'PAN number already registered.',
      );
      expect(
        vm.formatApiError('SQLSTATE[23000]: Duplicate entry uq_aadhaar'),
        'Aadhaar already registered.',
      );
      expect(
        vm.formatApiError('SQLSTATE error occurred'),
        'Information already in use.',
      );
      expect(
        vm.formatApiError('Network connection failed'),
        'Network connection failed',
      );
    });
  });
}
