import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'models/daily_record.dart';
import 'services/google_sheets_service.dart';
import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DayRecordApp());
}

class DayRecordApp extends StatelessWidget {
  const DayRecordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GoogleSheetsService()),
        ChangeNotifierProvider(create: (_) => RecordNotifier()),
      ],
      child: MaterialApp(
        title: '每日成長與開發實踐紀錄',
        theme: AppTheme.themeData,
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
