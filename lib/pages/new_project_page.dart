import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_record.dart';
import '../widgets/styled_widgets.dart';
import 'knowledge_page.dart';

class NewProjectPage extends StatefulWidget {
  const NewProjectPage({super.key});

  @override
  State<NewProjectPage> createState() => _NewProjectPageState();
}

class _NewProjectPageState extends State<NewProjectPage> {
  final _nameController = TextEditingController();
  final _progressController = TextEditingController();
  final _painPointsController = TextEditingController();
  final _problemsController = TextEditingController();
  final _solutionsController = TextEditingController();
  final _todosController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _progressController.dispose();
    _painPointsController.dispose();
    _problemsController.dispose();
    _solutionsController.dispose();
    _todosController.dispose();
    super.dispose();
  }

  void _onComplete() {
    context.read<RecordNotifier>().updateField((r) {
      r.projectName = _nameController.text;
      r.progressSummary = _progressController.text;
      r.technicalPainPoints = _painPointsController.text;
      r.problemsEncountered = _problemsController.text;
      r.solutions = _solutionsController.text;
      r.todos = _todosController.text;
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KnowledgePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '二、開發與實踐',
      bottomButton: StyledButton(
        text: '完成',
        onPressed: _onComplete,
      ),
      children: [
        StyledTextField(
          label: '項目名稱',
          hint: '輸入專案名稱',
          controller: _nameController,
          maxLines: 1,
        ),
        StyledTextField(
          label: '專案規劃',
          hint: '簡述今日進度',
          controller: _progressController,
        ),
        StyledTextField(
          label: '遭遇痛點',
          hint: '描述遇到的技術難點及解決方式',
          controller: _painPointsController,
        ),
        StyledTextField(
          label: '解決方案',
          hint: '描述報錯、邏輯卡點或 API 整合問題',
          controller: _problemsController,
        ),
        StyledTextField(
          label: '最終進度',
          hint: '紀錄使用的提示詞 Prompt、程式碼修復或 Git 同步處理方式',
          controller: _solutionsController,
        ),
        StyledTextField(
          label: '待辦事項',
          hint: '列出待完成的任務',
          controller: _todosController,
        ),
      ],
    );
  }
}
