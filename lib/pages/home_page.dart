import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/daily_record.dart';
import '../services/google_sheets_service.dart';
import '../widgets/styled_widgets.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登入失敗，請重試')),
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
                          const SizedBox(height: 16),
                          StyledButton(
                            text: 'START',
                            onPressed: _handleStart,
                            width: 200,
                          ),
                        ],
                      );
                    }
                    return StyledButton(
                      text: _signingIn ? '登入中...' : 'START',
                      onPressed: _handleStart,
                      isLoading: _signingIn,
                      width: 200,
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
