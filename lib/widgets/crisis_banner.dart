import 'package:flutter/material.dart';

import '../theme.dart';

/// Calm help banner shown when the safety check matches.
class CrisisBanner extends StatelessWidget {
  const CrisisBanner({super.key, this.onClose});
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: CozyColors.sage.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💛', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('You matter. Help is here right now.',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '• If you are in danger, call your local emergency number now.\n'
              '• US: call or text 988 (Suicide & Crisis Lifeline).\n'
              '• UK & Ireland: Samaritans 116 123.\n'
              '• Anywhere: findahelpline.com lists free, confidential lines in your country.\n'
              '• If someone is hurting you, a local domestic violence hotline can help you plan safely.',
            ),
          ],
        ),
      ),
    );
  }
}
