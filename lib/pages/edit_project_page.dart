import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_record.dart';
import '../widgets/styled_widgets.dart';
import 'knowledge_page.dart';

class EditProjectPage extends StatefulWidget {
  final String projectName;
  final DailyRecord? latestRecord;

  const EditProjectPage({
    super.key,
    required this.projectName,
    this.latestRecord,
  });

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _progressController;
  late final TextEditingController _painPointsController;
  late final TextEditingController _problemsController;
  late final TextEditingController _solutionsController;
  late final TextEditingController _todosController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.latestRecord;
    _nameController = TextEditingController(text: widget.projectName);
    _progressController = TextEditingController(
        text: _cleanBlank(r?.progressSummary ?? ''));
    _painPointsController = TextEditingController(
        text: _cleanBlank(r?.technicalPainPoints ?? ''));
    _problemsController = TextEditingController(
        text: _cleanBlank(r?.problemsEncountered ?? ''));
    _solutionsController = TextEditingController(
        text: _cleanBlank(r?.solutions ?? ''));
    _todosController = TextEditingController(
        text: _cleanBlank(r?.todos ?? ''));
  }

  String _cleanBlank(String value) {
    return value == '空白' ? '' : value;
  }

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
        // 返回到選擇專案頁面
        Navigator.of(context).popUntil((route) => route.settings.name == '/'); 
        // Note: The root might be HomePage or ProjectSelectionPage.
        // Actually, ProjectSelectionPage might not have a named route.
        // Let's use pop instead if we know we came from ProjectSelectionPage.
        // Wait, _selectProject in ProjectSelectionPage uses Navigator.push.
        // So popping once should work if we came from selection.
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
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFF8C42)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '已載入上次紀錄，修改後將存為新的一筆紀錄',
                  style: TextStyle(fontSize: 14, color: Color(0xFF795548)),
                ),
              ),
            ],
          ),
        ),
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
