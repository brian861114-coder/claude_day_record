import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_record.dart';
import '../services/google_sheets_service.dart';
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

  bool _saving = false;

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

  Future<void> _saveProject() async {
    final notifier = context.read<RecordNotifier>();
    final now = DateTime.now();
    final timestamp = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    notifier.updateField((r) {
      r.date = timestamp;
      r.projectName = _nameController.text;
      r.progressSummary = _progressController.text;
      r.technicalPainPoints = _painPointsController.text;
      r.problemsEncountered = _problemsController.text;
      r.solutions = _solutionsController.text;
      r.todos = _todosController.text;
    });

    final service = context.read<GoogleSheetsService>();
    final success = await service.appendProjectRecord(notifier.record);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.lastError ?? '儲存失敗，請重試'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      throw Exception('Save failed');
    }
  }

  Future<void> _onComplete() async {
    setState(() => _saving = true);
    try {
      await _saveProject();
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const KnowledgePage()),
        );
      }
    } catch (_) {
      // Error handled in _saveProject
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onUpdateOther() async {
    setState(() => _saving = true);
    try {
      await _saveProject();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      // Error handled in _saveProject
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '二、開發與實踐',
      bottomButton: Row(
        children: [
          Expanded(
            child: StyledButton(
              text: '更新其他計畫',
              onPressed: _onUpdateOther,
              isLoading: _saving,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StyledButton(
              text: '完成',
              onPressed: _onComplete,
              isLoading: _saving,
            ),
          ),
        ],
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
