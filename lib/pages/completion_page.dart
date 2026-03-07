import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/google_sheets_service.dart';

class CompletionPage extends StatelessWidget {
  const CompletionPage({super.key});

  Future<void> _openSheet() async {
    final uri = Uri.parse(GoogleSheetsService.spreadsheetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration,
                    size: 64,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '紀錄完成！',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  '紀錄使我們的時光不虛度',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 48),
                OutlinedButton.icon(
                  onPressed: _openSheet,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('查看 Google Sheets'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.accent),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    '回到首頁',
                    style: TextStyle(fontSize: 16, color: AppTheme.accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
