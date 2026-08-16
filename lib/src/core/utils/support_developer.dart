import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String supportDeveloperCashPlusNumber = '0619087436';

Future<void> showSupportDeveloperSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SupportDeveloperSheet(),
  );
}

class _SupportDeveloperSheet extends StatelessWidget {
  const _SupportDeveloperSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 40),
            const SizedBox(height: 14),
            Text(
              'دعم المطور',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'إذا عجبك التطبيق، تقدر تدعم المطور عبر Cash Plus (كاش بلوس) بتحويل أي مبلغ للرقم التالي:',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                supportDeveloperCashPlusNumber,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: supportDeveloperCashPlusNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ الرقم')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ الرقم'),
            ),
            const SizedBox(height: 10),
            Text(
              'توجّه لأقرب وكالة Cash Plus وحوّل المبلغ لهذا الرقم. شكرًا لدعمك! 🙏',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
