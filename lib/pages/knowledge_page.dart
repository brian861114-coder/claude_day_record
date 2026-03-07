import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_record.dart';
import '../widgets/styled_widgets.dart';
import 'health_page.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  final _topicController = TextEditingController();
  final _notesController = TextEditingController();
  final _applicationController = TextEditingController();
  final _questionsController = TextEditingController();

  @override
  void dispose() {
    _topicController.dispose();
    _notesController.dispose();
    _applicationController.dispose();
    _questionsController.dispose();
    super.dispose();
  }

  void _onComplete() {
    context.read<RecordNotifier>().updateField((r) {
      r.learningTopic = _topicController.text;
      r.keyNotes = _notesController.text;
      r.practicalApplication = _applicationController.text;
      r.questions = _questionsController.text;
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HealthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '知識輸入',
      bottomButton: StyledButton(
        text: '完成',
        onPressed: _onComplete,
      ),
      children: [
        StyledTextField(
          label: '學習主題',
          hint: '今天學習了什麼？',
          controller: _topicController,
          maxLines: 1,
        ),
        StyledTextField(
          label: '關鍵筆記',
          hint: '記下重要的知識點',
          controller: _notesController,
          maxLines: 5,
        ),
        StyledTextField(
          label: '實踐應用',
          hint: '這項知識如何應用在你的生活、日語練習或宏觀經濟研究中？',
          controller: _applicationController,
        ),
        StyledTextField(
          label: '疑問 / 待查證',
          hint: '還有什麼不確定或需要深入研究的？',
          controller: _questionsController,
        ),
      ],
    );
  }
}
