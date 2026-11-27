import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';

const String _font = 'Satoshi';
const Color _ink = Color(0xFF0B1B3A);

/// Shared step metadata for all 5 registration screens
class RegistrationStep {
  final int stepNumber; // 1-based
  final String label;
  final String timeEstimate;
  final String whyMessage;
  final String? rewardHint; // only for step 5

  const RegistrationStep({
    required this.stepNumber,
    required this.label,
    required this.timeEstimate,
    required this.whyMessage,
    this.rewardHint,
  });

  static const List<RegistrationStep> steps = [
    RegistrationStep(
      stepNumber: 1,
      label: 'Secure your account',
      timeEstimate: '',
      whyMessage: "We'll never share your email or mobile number",
      rewardHint: null,
    ),
    RegistrationStep(
      stepNumber: 2,
      label: 'Almost secured ✓',
      timeEstimate: '',
      whyMessage: 'Your password is encrypted — only you can access your account',
      rewardHint: null,
    ),
    RegistrationStep(
      stepNumber: 3,
      label: 'One-time only — never again',
      timeEstimate: '',
      whyMessage: 'Required by RBI for international transfers — 100% encrypted & never shared',
      rewardHint: null,
    ),
    RegistrationStep(
      stepNumber: 4,
      label: 'Your transfer profile',
      timeEstimate: '',
      whyMessage: 'Your profile is saved securely — come back anytime',
      rewardHint: null,
    ),
    RegistrationStep(
      stepNumber: 5,
      label: 'Final check — unlock transfers!',
      timeEstimate: '',
      whyMessage: 'This keeps your money safe from fraud — required by FEMA',
      rewardHint: 'Complete KYC & get ₹0 transfer fee on your first transaction!',
    ),
  ];
}

/// Animated progress header with Zeigarnik illusion (starts at 20% not 0%)
class RegistrationProgressHeader extends StatelessWidget {
  final int currentStep; // 1-based

  const RegistrationProgressHeader({super.key, required this.currentStep});

  double get _progressFraction {
    // Zeigarnik illusion: start at 0.20 for step 1, end at 1.0 for step 5
    // step1=0.20, step2=0.40, step3=0.60, step4=0.80, step5=1.0
    return 0.20 * currentStep;
  }

  @override
  Widget build(BuildContext context) {
    final step = RegistrationStep.steps[currentStep - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.label,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        // Animated segmented progress bar
        Row(
          children: List.generate(5, (index) {
            final stepNum = index + 1;
            final isDone = stepNum < currentStep;
            final isCurrent = stepNum == currentStep;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.PrimaryColor
                        : isCurrent
                            ? AppTheme.PrimaryColor.withOpacity(0.55)
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $currentStep of 5',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              '${((_progressFraction) * 100).toInt()}% Complete',
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.PrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // "Why we need this" trust message
        _WhyMessage(message: step.whyMessage),
        // Reward hint only on step 5
        if (step.rewardHint != null) ...[
          const SizedBox(height: 10),
          _RewardBanner(message: step.rewardHint!),
        ],
        const SizedBox(height: 6),
      ],
    );
  }
}

class _WhyMessage extends StatelessWidget {
  final String message;
  const _WhyMessage({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFE3FF), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xFF0F7B4F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A6B50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardBanner extends StatelessWidget {
  final String message;
  const _RewardBanner({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.PrimaryColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, size: 18, color: Color(0xFF7A5A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7A5A00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step completion celebration overlay — shown after each step succeeds
/// Usage: call StepCompletionOverlay.show(context, stepNumber) before navigating
class StepCompletionOverlay {
  static Future<void> show(BuildContext context, int completedStep) async {
    final messages = [
      'Account secured!',
      'Password set! Almost there',
      'Identity verified!',
      'Profile saved! One more step',
      'You\'re all set!',
    ];
    final message = completedStep >= 1 && completedStep <= 5
        ? messages[completedStep - 1]
        : 'Step complete!';

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim, _) => _StepDoneDialog(message: message),
      transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: child,
      ),
    );
  }
}

class _StepDoneDialog extends StatefulWidget {
  final String message;
  const _StepDoneDialog({required this.message});
  @override
  State<_StepDoneDialog> createState() => _StepDoneDialogState();
}

class _StepDoneDialogState extends State<_StepDoneDialog> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.PrimaryColor.withOpacity(0.25),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5F8E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF0F7B4F), size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Save & Continue banner shown when user tries to exit mid-flow
/// Usage: wrap Scaffold with WillPopScope or use PopScope and call this
class SaveProgressBanner {
  static Future<bool> showExitConfirmation(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.bookmark_rounded, color: AppTheme.PrimaryColor, size: 40),
            const SizedBox(height: 14),
            const Text(
              'Your progress is saved!',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Come back anytime — we\'ve saved exactly where you left off. Your data is 100% secure.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(true), // allow exit
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Exit', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w700, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false), // stay
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.PrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Continue Setup', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }
}

/// Social proof badge — shown on PAN/Sender/KYC steps
class SocialProofBadge extends StatelessWidget {
  const SocialProofBadge({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5D5FF), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded, size: 15, color: Color(0xFF5B5BD6)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontFamily: _font, fontSize: 12),
                children: [
                  TextSpan(text: 'Trusted by ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextSpan(text: '2,00,000+ Indians', style: TextStyle(color: Color(0xFF5B5BD6), fontWeight: FontWeight.w800)),
                  TextSpan(text: ' sending money abroad  •  ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextSpan(text: 'RBI Regulated', style: TextStyle(color: Color(0xFF0F7B4F), fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
