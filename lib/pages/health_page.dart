import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_record.dart';
import '../widgets/styled_widgets.dart';
import 'reflection_page.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final _dietController = TextEditingController();
  final _environmentController = TextEditingController();

  @override
  void dispose() {
    _dietController.dispose();
    _environmentController.dispose();
    super.dispose();
  }

  void _onComplete() {
    context.read<RecordNotifier>().updateField((r) {
      r.dietRecord = _dietController.text;
      r.environmentMaintenance = _environmentController.text;
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReflectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '生活與健康',
      bottomButton: StyledButton(
        text: '完成',
        onPressed: _onComplete,
      ),
      children: [
        StyledTextField(
          label: '身體健康努力',
          hint: '紀錄今天的飲食內容',
          controller: _dietController,
          maxLines: 4,
        ),
        StyledTextField(
          label: '環境維護與人際關係維護',
          hint: '今天做了哪些環境整理或維護？',
          controller: _environmentController,
          maxLines: 4,
        ),
      ],
    );
  }
}
