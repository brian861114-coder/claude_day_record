import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_record.dart';
import '../services/google_sheets_service.dart';
import '../widgets/styled_widgets.dart';
import 'completion_page.dart';

class ReflectionPage extends StatefulWidget {
  const ReflectionPage({super.key});

  @override
  State<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends State<ReflectionPage> {
  final _wellController = TextEditingController();
  final _improveController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _wellController.dispose();
    _improveController.dispose();
    super.dispose();
  }

  Future<void> _onComplete() async {
    setState(() => _saving = true);

    final notifier = context.read<RecordNotifier>();
    notifier.updateField((r) {
      r.whatWentWell = _wellController.text;
      r.whatToImprove = _improveController.text;
    });

    // Fill blanks
    notifier.record.fillBlanks();

    // Write to Google Sheets
    final service = context.read<GoogleSheetsService>();
    final success = await service.appendRecord(notifier.record);

    if (mounted) {
      setState(() => _saving = false);

      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CompletionPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(service.lastError ?? '儲存失敗，請檢查網路連線後重試'),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '今日反思',
      bottomButton: StyledButton(
        text: '完成',
        onPressed: _onComplete,
        isLoading: _saving,
      ),
      children: [
        StyledTextField(
          label: '做得好的地方',
          hint: '今天有什麼值得肯定的成果？',
          controller: _wellController,
          maxLines: 4,
        ),
        StyledTextField(
          label: '明天可以改進的地方',
          hint: '明天可以怎樣做得更好？',
          controller: _improveController,
          maxLines: 4,
        ),
      ],
    );
  }
}
