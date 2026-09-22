class ApiConstants {
  static const String baseUrl = 'https://www.payfxglobal.com';
  static const String sendOtpUrl = '$baseUrl/app/customer/add';
  static const String sendOtpUrl2 = '$baseUrl/app/customer/add2';
  static const String verifyOtpUrl = '$baseUrl/app/customer/verifyotp';
  static const String newUserRegUrl = '$baseUrl/app/customer/register';
  static const String verifyPanUrl = '$baseUrl/app/customer/verifypan';
  static const String verifyPanUrl2 = '$baseUrl/app/customer/verifypan';
  static const String getCountriesUrl = '$baseUrl/app/customer/getcountry';
  static const String getUniversitiesUrl = '$baseUrl/app/customer/universities';
  static const String getStatesUrl = '$baseUrl/app/customer/getstates';
  static const String saveSenderUrl = '$baseUrl/app/customer/addsender';
  static const String paymentReturnUrl = '$baseUrl/app/customer/checkPaymentStatus';
  static const String paymentMethodUrl = '$baseUrl/app/customer/paymentMode';
  static const String checkSenderDetailsUrl =
      '$baseUrl/app/customer/checksender';
  static const String checkQuestionsAnswersUrl =
      '$baseUrl/app/customer/checkquestionsanswers';
  static const String checkUploadedFilesUrl =
      '$baseUrl/app/customer/checkuploadedfiles';
  static const String submitKyc = '$baseUrl/app/customer/submitkyc';
  static const String getSourceOfFundUrl = '$baseUrl/app/customer/sourceoffund';
  static const String getOccupationsUrl = '$baseUrl/app/customer/occupation';
  static const String getReasonsUrl = '$baseUrl/app/customer/reasons';
  static const String getDeliveryMethodUrl =
      '$baseUrl/app/customer/deliverymethod';
  static const String createTransactionUrl =
      '$baseUrl/app/customer/storedeliverymethod';
  static const String getOfflinePaymentUrl =
      '$baseUrl/app/customer/offlinepaymentdetails';
  static const String getDownloadTUrl =
      '$baseUrl/app/customer/offlinepaymentdetails';
  static const String getSubmitUtrUrl = '$baseUrl/app/customer/apisubmitutr';
  static const String loginUrl = '$baseUrl/app/customer/login';
  static const String googleLoginUrl = '$baseUrl/app/customer/googleLogin';
  static const String logoutUrl = '$baseUrl/app/customer/logout';
  static const String updatePasswordUrl =
      '$baseUrl/app/customer/updatePassword';
  static const String fullProfileUrl = '$baseUrl/app/customer/full-profile';
  static const String updateProfileUrl = '$baseUrl/app/customer/update-profile';
  static const String changePasswordUrl =
      '$baseUrl/app/customer/change-password';
  static const String deleteAccountUrl = '$baseUrl/app/customer/deleteAccount';
  static const String storeTransactionUrl =
      '$baseUrl/app/customer/store-transaction-data';
  static const String transactionSummaryUrl =
      '$baseUrl/app/customer/transaction-summary';
  static const String downloadBillUrl =
      '$baseUrl/app/customer/transaction/bill';
  static const String recipientListUrl = '$baseUrl/app/customer/recipient-list';
  static const String selectRecipientUrl =
      '$baseUrl/app/customer/selectrecipient';
  static const String deleteRecipientUrl =
      '$baseUrl/app/customer/deleteRecipient';
  static const String checkSelfRemittanceUrl =
      '$baseUrl/app/customer/check-self-remittance';
  static const String getCurrencyRatesUrl =
      '$baseUrl/api_flutter/get_currency_rates.php';
  static const String createLoanApplicantUrl = '$baseUrl/loan_applicant.php';
  static const String todayIbrRateUrl = '$baseUrl/app/customer/today-ibr-rate';
}
