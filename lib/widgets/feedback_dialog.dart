import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import 'package:payfxglobal/widgets/custom_button.dart';

class FeedbackDialog extends StatefulWidget {
  final Function(int rating, String comment) onSubmit;

  const FeedbackDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await UserStorage.getUserFullName();
    final email = await UserStorage.getUserEmail();
    if (mounted) {
      setState(() {
        _userName = name ?? 'Customer';
        _userEmail = email ?? 'Not provided';
      });
    }
  }

  Future<void> _sendEmailNotification(int rating, String comment) async {
    final dio = Dio();
    const String url = "https://api.zeptomail.in/v1.1/email";
    const String apiKey =
        "PHtE6r0PFrjo2TYo9hACtPHqE8GjPIos+uo0KwcRsNtHAvULHU1Xo4gomzO1+h1+V6VEHKSbzto65O6fs+PQI2zlMTtOW2qyqK3sx/VYSPOZsbq6x00ctVUedkfYXIDvdtJj1izWsteX";

    final String htmlBody = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Customer Feedback</title>
</head>

<body style="margin:0; padding:0; background-color:#f5f5f5; font-family:Arial, Helvetica, sans-serif;">

  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#f5f5f5;">
    <tr>
      <td align="center" style="padding:30px 15px;">

```
    <table width="600" cellpadding="0" cellspacing="0" border="0"
      style="width:100%; max-width:600px; background-color:#ffffff;">

      <!-- Header -->
      <tr>
        <td style="background-color:#363D59; padding:25px 30px;">
          <img
            src="https://www.payfxglobal.com/assets/img/logo.png"
            alt="PayFX Global"
            width="140"
            style="display:block; border:0;"
          >
        </td>
      </tr>

      <!-- Yellow Line -->
      <tr>
        <td style="height:4px; background-color:#F9C63D; font-size:0;">
          &nbsp;
        </td>
      </tr>

      <!-- Content -->
      <tr>
        <td style="padding:30px;">

          <h2 style="margin:0 0 10px 0; color:#363D59; font-size:22px;">
            New Customer Feedback
          </h2>

          <p style="margin:0 0 25px 0; color:#666666; font-size:14px; line-height:1.6;">
            We have received new customer feedback through the PayFX Global mobile application.
          </p>

          <!-- Feedback Details -->
          <table width="100%" cellpadding="0" cellspacing="0" border="0"
            style="border:1px solid #e5e5e5;">

            <tr>
              <td colspan="2"
                style="padding:15px; background-color:#f8f8f8; color:#363D59; font-size:14px; font-weight:bold;">
                Feedback Details
              </td>
            </tr>

            <!-- Customer Name -->
            <tr>
              <td width="35%"
                style="padding:12px 15px; color:#777777; font-size:13px; border-top:1px solid #eeeeee;">
                Customer Name
              </td>
              <td
                style="padding:12px 15px; color:#363D59; font-size:14px; font-weight:bold; border-top:1px solid #eeeeee;">
                $_userName
              </td>
            </tr>

            <!-- Customer Email -->
            <tr>
              <td
                style="padding:12px 15px; color:#777777; font-size:13px; border-top:1px solid #eeeeee;">
                Customer Email
              </td>
              <td
                style="padding:12px 15px; color:#363D59; font-size:14px; font-weight:bold; border-top:1px solid #eeeeee;">
                $_userEmail
              </td>
            </tr>

            <!-- Rating -->
            <tr>
              <td
                style="padding:12px 15px; color:#777777; font-size:13px; border-top:1px solid #eeeeee;">
                Rating
              </td>
              <td
                style="padding:12px 15px; color:#363D59; font-size:14px; font-weight:bold; border-top:1px solid #eeeeee;">
                $rating / 5 Stars
              </td>
            </tr>

            <!-- Comments -->
            <tr>
              <td
                style="padding:12px 15px; color:#777777; font-size:13px; border-top:1px solid #eeeeee; vertical-align:top;">
                Comments
              </td>
              <td
                style="padding:12px 15px; color:#363D59; font-size:14px; line-height:1.6; border-top:1px solid #eeeeee;">
                $comment
              </td>
            </tr>

          </table>

          <!-- Message -->
          <p style="margin:25px 0 0 0; color:#666666; font-size:14px; line-height:1.6;">
            Please review this feedback to help us improve our services.
          </p>

          <p style="margin:20px 0 0 0; color:#363D59; font-size:14px; line-height:1.6;">
            Warm regards,<br>
            <strong>PayFX Global Support Team</strong>
          </p>

        </td>
      </tr>

      <!-- Footer -->
      <tr>
        <td
          style="background-color:#363D59; padding:18px; text-align:center; color:#ffffff; font-size:12px;">
          © 2026 PayFX Global. All rights reserved.
        </td>
      </tr>

    </table>

  </td>
</tr>
```

  </table>

</body>
</html>

""";

    final payload = {
      "from": {
        "address": "care@payfxglobal.com",
        "name": "PayFX App Customer Feedback",
      },
      "to": [
        {
          "email_address": {
            "address": "manoj.kumar@payfx.co.in",
            "name": "Manoj",
          },
        },
      ],
      "cc": [
        {
          "email_address": {
            "address": "yasotha@payfx.co.in",
            "name": "Support Team",
          },
        },
        {
          "email_address": {
            "address": "jp@payfx.co.in",
            "name": "Support Team",
          },
        },
        {
          "email_address": {
            "address": "ithelp@payfx.co.in",
            "name": "Support Team",
          },
        },
      ],
      "subject": "App Customer Feedback - $_userName",
      "htmlbody": htmlBody,
    };

    try {
      final response = await dio.post(
        url,
        data: payload,
        options: Options(
          headers: {
            "accept": "application/json",
            "authorization": "Zoho-enczapikey $apiKey",
            "content-type": "application/json",
          },
        ),
      );

      debugPrint("Email API Response: ${response.data}");
    } catch (e) {
      debugPrint("Email API Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share Your Feedback',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.TextColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'How was your experience with PayFX Global?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedRating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      color: index < _selectedRating ? Colors.amber : Colors.grey,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                cursorColor: AppTheme.PrimaryColor,
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write your comments here...',
                  hintStyle: const TextStyle(fontFamily: 'Satoshi', fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.PrimaryColor, width: 2.0),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                title: 'Submit',
                onPressed: _selectedRating == 0
                    ? null
                    : () {
                        final rating = _selectedRating;
                        final comment = _commentController.text;
                        _sendEmailNotification(rating, comment);
                        widget.onSubmit(rating, comment);
                        Navigator.pop(context);
                      },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
