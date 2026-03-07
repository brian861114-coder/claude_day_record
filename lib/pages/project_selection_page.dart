import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/google_sheets_service.dart';
import '../widgets/styled_widgets.dart';
import 'new_project_page.dart';
import 'edit_project_page.dart';

class ProjectSelectionPage extends StatefulWidget {
  const ProjectSelectionPage({super.key});

  @override
  State<ProjectSelectionPage> createState() => _ProjectSelectionPageState();
}

class _ProjectSelectionPageState extends State<ProjectSelectionPage> {
  List<String>? _projects;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final service = context.read<GoogleSheetsService>();
      final projects = await service.getProjectNames();
      if (mounted) {
        setState(() {
          _projects = projects;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '無法載入專案列表：$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectProject(String projectName) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final service = context.read<GoogleSheetsService>();
    final latestRecord = await service.getLatestRecord(projectName);

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditProjectPage(
            projectName: projectName,
            latestRecord: latestRecord,
          ),
        ),
      );
    }
  }

  void _createNewProject() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewProjectPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '選擇專案',
      bottomButton: StyledButton(
        text: '＋ 新專案',
        onPressed: _createNewProject,
      ),
      children: [
        const Text(
          '選擇要繼續的專案，或建立新專案',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 24),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          )
        else if (_error != null)
          Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadProjects();
                  },
                  child: const Text('重試'),
                ),
              ],
            ),
          )
        else if (_projects == null || _projects!.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    '尚無專案紀錄\n點擊下方按鈕建立第一個專案',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_projects!.map(
            (name) => ProjectButton(
              name: name,
              onTap: () => _selectProject(name),
            ),
          )),
      ],
    );
  }
}
