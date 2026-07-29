class AppConstants {
  // App Information
  static const String appName = 'PayFX Global';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://api.payuni.com';
  static const String apiVersion = 'v1';

  // Storage Keys
  static const String userToken = 'user_token';
  static const String userProfile = 'user_profile';
  static const String isFirstTime = 'is_first_time';
  static const String biometricEnabled = 'biometric_enabled';

  // Transaction Types
  static const String sendMoney = 'send_money';
  static const String receiveMoney = 'receive_money';
  static const String billPayment = 'bill_payment';
  static const String topUp = 'top_up';
  static const String withdraw = 'withdraw';

  // Transaction Status
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';

  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  static const double minTransferAmount = 1.0;
  static const double maxTransferAmount = 10000.0;
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 5;

  // Supported Currencies
  static const List<String> supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'JPY',
    'INR',
    'NGN',
  ];

  // Payment Methods
  static const String bankTransfer = 'bank_transfer';
  static const String creditCard = 'credit_card';
  static const String debitCard = 'debit_card';
  static const String wallet = 'wallet';

  // Countries
  static const List<Map<String, String>> supportedCountries = [
    {'code': 'US', 'name': 'United States', 'currency': 'USD'},
    {'code': 'GB', 'name': 'United Kingdom', 'currency': 'GBP'},
    {'code': 'CA', 'name': 'Canada', 'currency': 'CAD'},
    {'code': 'AU', 'name': 'Australia', 'currency': 'AUD'},
    {'code': 'NG', 'name': 'Nigeria', 'currency': 'NGN'},
    {'code': 'IN', 'name': 'India', 'currency': 'INR'},
    {'code': 'JP', 'name': 'Japan', 'currency': 'JPY'},
    {'code': 'DE', 'name': 'Germany', 'currency': 'EUR'},
  ];

  // Error Messages
  static const String networkError =
      'Network connection error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError =
      'An unknown error occurred. Please try again.';
  static const String invalidCredentials = 'Invalid email or password.';
  static const String emailAlreadyExists =
      'An account with this email already exists.';
  static const String weakPassword =
      'Password is too weak. Please choose a stronger password.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String invalidPhoneNumber = 'Please enter a valid phone number.';
  static const String insufficientBalance =
      'Insufficient balance for this transaction.';
  static const String invalidOtp = 'Invalid OTP. Please try again.';
  static const String otpExpired = 'OTP has expired. Please request a new one.';

  // Success Messages
  static const String loginSuccess = 'Login successful!';
  static const String registrationSuccess = 'Registration successful!';
  static const String transferSuccess =
      'Money transfer completed successfully!';
  static const String otpSent = 'OTP sent to your registered phone number.';
  static const String passwordResetSuccess =
      'Password reset link sent to your email.';
  static const String profileUpdated = 'Profile updated successfully!';

  // Regular Expressions
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
  static const String nameRegex = r'^[a-zA-Z\s]{2,50}$';

  // Time Constants
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration splashDelay = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Assets
  static const String logoPath = 'assets/images/logo.png';
  static const String splashLogoPath = 'assets/images/splash_logo.png';
  static const String placeholderAvatar =
      'assets/images/placeholder_avatar.png';

  // Dimensions
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;
  static const double buttonHeight = 48.0;
  static const double cardElevation = 4.0;
  static const double borderRadius = 12.0;
}
