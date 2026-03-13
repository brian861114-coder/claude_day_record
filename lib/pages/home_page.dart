import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/daily_record.dart';
import '../services/google_sheets_service.dart';
import '../widgets/styled_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core_goal_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _signingIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoogleSheetsService>().initialize();
    });
  }

  Future<void> _handleStart() async {
    final sheetsService = context.read<GoogleSheetsService>();

    if (!sheetsService.isSignedIn) {
      setState(() => _signingIn = true);
      final success = await sheetsService.signIn();
      setState(() => _signingIn = false);

      if (!success) {
        if (mounted) {
          final error = sheetsService.lastError ?? '登入失敗，請重試';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
        return;
      }
    }

    if (mounted) {
      context.read<RecordNotifier>().reset();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CoreGoalPage()),
      );
    }
  }

  Future<void> _handleViewRecords() async {
    final url = Uri.parse(GoogleSheetsService.spreadsheetUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法開啟連結')),
        );
      }
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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    size: 56,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '每日成長與\n開發實踐紀錄',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  '紀錄每一天的學習與成長',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 48),
                Consumer<GoogleSheetsService>(
                  builder: (context, service, _) {
                    if (service.isSignedIn) {
                      return Column(
                        children: [
                          Text(
                            '歡迎, ${service.userName ?? ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          StyledButton(
                            text: 'START',
                            onPressed: _handleStart,
                            width: 200,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _handleViewRecords,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(200, 56),
                              side: const BorderSide(color: AppTheme.accent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              '查看過去紀錄',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => service.forceSignIn(),
                            child: const Text(
                              '重新授權 (如果無法讀取資料)',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        StyledButton(
                          text: _signingIn ? '登入中...' : 'START',
                          onPressed: _handleStart,
                          isLoading: _signingIn,
                          width: 200,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _handleViewRecords,
                          child: const Text(
                            '查看過去紀錄',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
