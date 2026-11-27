import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ErrorReportService {
  ErrorReportService._();

  static final ErrorReportService instance = ErrorReportService._();

  static const String _url = 'https://api.zeptomail.in/v1.1/email';

  // Configured via compile-time environment variable (--dart-define=ZEPTOMAIL_API_KEY=...)
  // Default to empty to prevent hardcoding live third-party secrets in the client binary.
  static const String _apiKey = String.fromEnvironment('ZEPTOMAIL_API_KEY', defaultValue: '');
  static const String _fromEmail = 'care@payfxglobal.com';
  static const String _fromName = 'PayFX Global Error Monitor';

  static const String _toEmail = 'manoj.kumar@payfx.co.in';

  static const List<String> _ccEmails = [
    'barani@payfxglobal.com',
    'akash.v@payfxglobal.com',
  ];

  static const Duration _duplicateWindow = Duration(seconds: 10);
  static const int _maxEmailsPerMinute = 20;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  final Map<String, DateTime> _lastReported = {};
  final List<DateTime> _recentEmails = [];


  String _htmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  String _redact(String value) {
    var result = value;

    // Redact sensitive keys

    result = result.replaceAll(
      RegExp(
        r'''(authorization|password|passwd|access_token|refresh_token|api_key|apikey|secret|otp)\s*[:=]\s*(["']?)[^,\s"']+''',
        caseSensitive: false,
      ),
      '[REDACTED]',
    );

    // Redact emails
    result = result.replaceAll(
      RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}'),
      '[EMAIL]',
    );

    // Redact phone numbers (simple pattern)
    result = result.replaceAll(
      RegExp(r'(?<!\d)\+?\d[\d\s-]{8,}\d(?!\d)'),
      '[PHONE]',
    );

    if (result.length > 6000) {
      result = result.substring(0, 6000);
    }

    return result;
  }

  bool _canSend(String fingerprint, {bool compulsory = false}) {
    if (compulsory) return true;

    final now = DateTime.now();

    final previous = _lastReported[fingerprint];
    if (previous != null && now.difference(previous) < _duplicateWindow) {
      return false;
    }

    _recentEmails.removeWhere(
      (time) => now.difference(time) >= const Duration(minutes: 1),
    );

    if (_recentEmails.length >= _maxEmailsPerMinute) {
      return false;
    }

    _lastReported[fingerprint] = now;
    _recentEmails.add(now);

    return true;
  }

  Future<void> reportError({
    required Object error,
    required StackTrace stackTrace,
    required String screen,
    required String operation,
    String? method,
    Uri? requestUri,
    int? statusCode,
    Map<String, dynamic>? extraData,
    bool compulsory = true,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        debugPrint('❌ Email report failed: ZeptoMail API key is empty.');
        return;
      }

      if (_toEmail.isEmpty || _fromEmail.isEmpty) {
        debugPrint('❌ Email report failed: sender or recipient is empty.');
        return;
      }

      final safeError = _redact(error.toString());
      final safeStack = _redact(stackTrace.toString());

      // Do not include query parameters because they may contain sensitive data.
      final safeUrl = requestUri == null
          ? 'Not available'
          : '${requestUri.scheme}://${requestUri.host}${requestUri.path}';

      final fingerprint =
          '$screen|$operation|$statusCode|$safeError';

      if (!_canSend(fingerprint, compulsory: compulsory)) {
        debugPrint(
          '⚠️ Email report skipped: duplicate error or rate limit reached.',
        );
        return;
      }

      final eventId =
          DateTime.now().toUtc().microsecondsSinceEpoch.toString();
      final timestamp = DateTime.now().toUtc().toIso8601String();

      final details = <String, String>{
        'Event ID': eventId,
        'Time (UTC)': timestamp,
        'App': 'PayFX Global',
        'App Version': '1.18',
        'Platform': kIsWeb ? 'Web' : Platform.operatingSystem,
        'Screen': _redact(screen),
        'Operation': _redact(operation),
        'HTTP Method': method ?? 'Not available',
        'Request URL': safeUrl,
        'HTTP Status': statusCode?.toString() ?? 'Not available',
        'Error': safeError,
        if (extraData != null)
          ...extraData.map((k, v) => MapEntry(k, _redact(v?.toString() ?? 'null'))),
        'Stack Trace': safeStack,
      };

      final rows = details.entries.map((entry) {
        final isError = entry.key == 'Error' || entry.key == 'Server Response';
        return '''
        <tr>
          <td style="padding:10px;border:1px solid #ddd;
                     background:#f5f6f8;font-weight:bold;
                     vertical-align:top;width:180px;">
            ${_htmlEscape(entry.key)}
          </td>
          <td style="padding:10px;border:1px solid #ddd;
                     white-space:pre-wrap;word-break:break-word;${isError ? 'color:#b30000;font-weight:600;' : ''}">
            ${_htmlEscape(entry.value)}
          </td>
        </tr>
      ''';
      }).join();

      final htmlBody = '''
    <!DOCTYPE html>
    <html>
    <body style="font-family:Arial,sans-serif;color:#363D59;">
      <div style="background:#363D59;padding:20px;color:white;">
        <h2 style="margin:0;">PayFX Global - Production Error</h2>
      </div>
      <div style="height:4px;background:#F9C63D;"></div>
      <div style="padding:20px;">
        <p>An application error has been reported.</p>
        <p><b>Event ID:</b> ${_htmlEscape(eventId)}</p>
        <table style="border-collapse:collapse;width:100%;font-size:13px;">
          $rows
        </table>
        <p style="color:#777;font-size:12px;">
          Automated diagnostic notification. Do not reply.
        </p>
      </div>
    </body>
    </html>
    ''';

      final payload = {
        'from': {
          'address': _fromEmail,
          'name': _fromName,
        },
        'to': [
          {
            'email_address': {
              'address': _toEmail,
              'name': 'Development Team',
            },
          },
        ],
        'cc': _ccEmails.map((email) {
          return {
            'email_address': {
              'address': email,
            },
          };
        }).toList(),
        'subject': '[PayFX Global] Production Error - $screen',
        'htmlbody': htmlBody,
      };

      debugPrint('📧 Sending production error report...');
      debugPrint('🆔 Event ID: $eventId');
      debugPrint('📍 Screen: $screen');
      debugPrint('⚙️ Operation: $operation');

      try {
        final response = await _dio.post(
          _url,
          data: jsonEncode(payload),
          options: Options(
            headers: {
              'accept': 'application/json',
              'authorization': 'Zoho-enczapikey $_apiKey',
              'content-type': 'application/json',
            },
            // Let us inspect unexpected HTTP status codes ourselves.
            validateStatus: (status) =>
            status != null && status >= 200 && status < 600,
          ),
        );

        final code = response.statusCode ?? 0;

        if (code >= 200 && code < 300) {
          debugPrint('✅ ZEPTOMAIL ACCEPTED THE ERROR REPORT REQUEST');
          debugPrint('📧 Recipient: $_toEmail');
          debugPrint('📨 HTTP Status: $code');
          debugPrint('🆔 Event ID: $eventId');
          debugPrint('📋 ZeptoMail response: ${response.data}');
        } else {
          debugPrint('❌ ZEPTOMAIL REJECTED THE ERROR REPORT REQUEST');
          debugPrint('📨 HTTP Status: $code');
          debugPrint('📋 ZeptoMail response: ${response.data}');
        }
      } on DioException catch (e) {
        debugPrint('❌ ERROR REPORT REQUEST FAILED');
        debugPrint('📨 HTTP Status: ${e.response?.statusCode}');
        debugPrint('📋 Response: ${e.response?.data}');
        debugPrint('🔎 Error: ${e.message}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ UNEXPECTED ERROR WHILE REPORTING AN ERROR');
      debugPrint('🔎 Error: $e');
      debugPrint('📚 Stack trace: $stackTrace');
    }
  }

}
