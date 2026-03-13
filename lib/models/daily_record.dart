import 'package:flutter/foundation.dart';

class DailyRecord {
  String date;
  String coreGoal;
  String projectName;
  String progressSummary;
  String technicalPainPoints;
  String problemsEncountered;
  String solutions;
  String todos;
  String learningTopic;
  String keyNotes;
  String practicalApplication;
  String questions;
  String dietRecord;
  String environmentMaintenance;
  String whatWentWell;
  String whatToImprove;

  DailyRecord({
    this.date = '',
    this.coreGoal = '',
    this.projectName = '',
    this.progressSummary = '',
    this.technicalPainPoints = '',
    this.problemsEncountered = '',
    this.solutions = '',
    this.todos = '',
    this.learningTopic = '',
    this.keyNotes = '',
    this.practicalApplication = '',
    this.questions = '',
    this.dietRecord = '',
    this.environmentMaintenance = '',
    this.whatWentWell = '',
    this.whatToImprove = '',
  });

  static const List<String> headers = [
    '日期',
    '今日核心目標',
    '學習主題',
    '關鍵筆記',
    '實踐應用',
    '疑問/待查證',
    '身體健康努力',
    '環境維護與人際關係維護',
    '做得好的地方',
    '明天可以改進的地方',
  ];

  static const List<String> projectHeaders = [
    '日期',
    '項目名稱',
    '進度摘要',
    '技術痛點與解決',
    '遇見問題',
    '解決方案',
    '待辦事項',
  ];

  List<String> toRow() {
    return [
      date,
      coreGoal,
      learningTopic,
      keyNotes,
      practicalApplication,
      questions,
      dietRecord,
      environmentMaintenance,
      whatWentWell,
      whatToImprove,
    ];
  }

  List<String> toProjectRow() {
    return [
      date,
      projectName,
      progressSummary,
      technicalPainPoints,
      problemsEncountered,
      solutions,
      todos,
    ];
  }

  static DailyRecord fromRow(List<dynamic> row) {
    String get(int i) => i < row.length ? row[i].toString() : '';
    // This fromRow is used for Sheet1, but since Sheet1 now excludes project fields,
    // we might need a separate fromProjectRow or handle it carefully.
    // However, the current getProjectNames and getLatestRecord logic in service
    // uses the C column of the active sheet. If projects are moved to another sheet,
    // we need to update those methods too.
    return DailyRecord(
      date: get(0),
      coreGoal: get(1),
      learningTopic: get(2),
      keyNotes: get(3),
      practicalApplication: get(4),
      questions: get(5),
      dietRecord: get(6),
      environmentMaintenance: get(7),
      whatWentWell: get(8),
      whatToImprove: get(9),
    );
  }

  static DailyRecord fromProjectRow(List<dynamic> row) {
    String get(int i) => i < row.length ? row[i].toString() : '';
    return DailyRecord(
      date: get(0),
      projectName: get(1),
      progressSummary: get(2),
      technicalPainPoints: get(3),
      problemsEncountered: get(4),
      solutions: get(5),
      todos: get(6),
    );
  }

  void fillBlanks() {
    if (coreGoal.trim().isEmpty) coreGoal = '空白';
    if (projectName.trim().isEmpty) projectName = '空白';
    if (progressSummary.trim().isEmpty) progressSummary = '空白';
    if (technicalPainPoints.trim().isEmpty) technicalPainPoints = '空白';
    if (problemsEncountered.trim().isEmpty) problemsEncountered = '空白';
    if (solutions.trim().isEmpty) solutions = '空白';
    if (todos.trim().isEmpty) todos = '空白';
    if (learningTopic.trim().isEmpty) learningTopic = '空白';
    if (keyNotes.trim().isEmpty) keyNotes = '空白';
    if (practicalApplication.trim().isEmpty) practicalApplication = '空白';
    if (questions.trim().isEmpty) questions = '空白';
    if (dietRecord.trim().isEmpty) dietRecord = '空白';
    if (environmentMaintenance.trim().isEmpty) environmentMaintenance = '空白';
    if (whatWentWell.trim().isEmpty) whatWentWell = '空白';
    if (whatToImprove.trim().isEmpty) whatToImprove = '空白';
  }
}

class RecordNotifier extends ChangeNotifier {
  DailyRecord _record = DailyRecord();

  DailyRecord get record => _record;

  void reset() {
    _record = DailyRecord();
    final now = DateTime.now();
    _record.date =
        '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  void updateField(void Function(DailyRecord r) updater) {
    updater(_record);
    notifyListeners();
  }
}
