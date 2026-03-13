import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_record.dart';
import '../widgets/styled_widgets.dart';
import 'project_selection_page.dart';

class CoreGoalPage extends StatefulWidget {
  const CoreGoalPage({super.key});

  @override
  State<CoreGoalPage> createState() => _CoreGoalPageState();
}

class _CoreGoalPageState extends State<CoreGoalPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onComplete() {
    context.read<RecordNotifier>().updateField((r) {
      r.coreGoal = _controller.text;
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectSelectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '一、今日核心目標',
      bottomButton: StyledButton(
        text: '完成',
        onPressed: _onComplete,
      ),
      children: [
        const Text(
          '今天最想達成的目標是什麼？',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        StyledTextField(
          label: '核心目標',
          hint: '填寫今天最想解決的一個問題或學習的一個重點，例如：優化 YOLO 監測邏輯或 Flutter UI 調整',
          controller: _controller,
          maxLines: 5,
        ),
      ],
    );
  }
}
