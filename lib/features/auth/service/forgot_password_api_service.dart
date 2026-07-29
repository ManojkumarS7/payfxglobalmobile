import 'dart:convert';
import 'dart:io';
import 'package:file_picker/src/platform_file.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:payfxglobal/utils/api_constants2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../services/api_service.dart';



class ForgotPasswordApiService {


   Future<Map<String, dynamic>> sendOtp2({required String email}) async {
    final response = await http.post(
      Uri.parse(ApiConstants.sendOtpUrl2),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),


    );
    return jsonDecode(response.body);
  }



   Future<Map<String, dynamic>> verifyForgotPasswordOtp({
     required String email,
     required String otp,
   }) async {
     return await ApiService.verifyOtp(
       email: email,
       otp: otp,
     );
   }

   Future<Map<String, dynamic>> resetPassword({
     required String email,
     required String newPassword,
   }) async {
     return await ApiService.resetPassword(
       email: email,
       newPassword: newPassword,
     );
   }


}