import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/sheets/v4.dart';
import '../models/daily_record.dart';

class GoogleSheetsService extends ChangeNotifier {
  static const String spreadsheetId =
      '11gb_lVWqomuKTqFG6H_4sRVYikHn2ZNvB5bfeycjLbE';
  static const String webClientId =
      '640508411383-0igbekbk5uk4g04td82fbath7ug48brt.apps.googleusercontent.com';
  
  // 優先嘗試的分頁名稱列表
  static const List<String> _possibleSheetNames = ['Sheet1', '工作表1'];
  String _activeSheetName = 'Sheet1';

  static const List<String> _scopes = [
    SheetsApi.spreadsheetsScope,
  ];

  late final GoogleSignIn _googleSignIn;

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  String? _userName;
  String? get userName => _userName;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SheetsApi? _sheetsApi;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _googleSignIn = GoogleSignIn(
      // Web 版需要明確指定 clientId；手機版從設定檔讀取
      clientId: kIsWeb ? webClientId : null,
      scopes: _scopes,
    );

    _googleSignIn.onCurrentUserChanged.listen((account) async {
      if (account != null) {
        _isSignedIn = true;
        _userName = account.displayName;
        _sheetsApi = null;
        notifyListeners();
        await _ensureSheetsApi();
      } else {
        _isSignedIn = false;
        _userName = null;
        _sheetsApi = null;
        notifyListeners();
      }
    });

    // 嘗試靜默登入（之前已登入的使用者）
    await _googleSignIn.signInSilently();
  }

  Future<bool> signIn() async {
    _isLoading = true;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      await _ensureSheetsApi();
      return _isSignedIn;
    } catch (e) {
      debugPrint('Sign in error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _sheetsApi = null;
  }

  Future<void> _ensureSheetsApi() async {
    if (_sheetsApi != null) return;

    try {
      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) return;
      _sheetsApi = SheetsApi(authClient);
      await _detectActiveSheet();
      await ensureHeaders();
    } catch (e) {
      debugPrint('Error creating Sheets API client: $e');
    }
  }

  Future<void> _detectActiveSheet() async {
    if (_sheetsApi == null) return;

    for (final name in _possibleSheetNames) {
      try {
        await _sheetsApi!.spreadsheets.values.get(
          spreadsheetId,
          '$name!A1:A1',
        );
        _activeSheetName = name;
        debugPrint('Detected active sheet: $_activeSheetName');
        return;
      } catch (e) {
        debugPrint('Sheet "$name" not found, trying next...');
      }
    }
    debugPrint('Warning: No known sheet names found. Falling back to $_activeSheetName');
  }

  Future<void> ensureHeaders() async {
    if (_sheetsApi == null) return;

    try {
      final response = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        '$_activeSheetName!A1:P1',
      );

      final firstCell = response.values?.isNotEmpty == true
          ? response.values![0].isNotEmpty
              ? response.values![0][0].toString()
              : ''
          : '';

      if (firstCell != '日期') {
        final headerRange = ValueRange.fromJson({
          'values': [DailyRecord.headers],
        });
        await _sheetsApi!.spreadsheets.values.update(
          headerRange,
          spreadsheetId,
          '$_activeSheetName!A1:P1',
          valueInputOption: 'RAW',
        );
        debugPrint('Google Sheets 欄位標題已建立');
      }
    } catch (e) {
      debugPrint('Error ensuring headers: $e');
    }
  }

  Future<List<String>> getProjectNames() async {
    await _ensureSheetsApi();
    if (_sheetsApi == null) return [];

    try {
      final response = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        '$_activeSheetName!C:C',
      );

      if (response.values == null) {
        debugPrint('No values found in $_activeSheetName!C:C');
        return [];
      }

      final names = <String>{};
      for (int i = 1; i < response.values!.length; i++) {
        final row = response.values![i];
        if (row.isNotEmpty) {
          final name = row[0].toString().trim();
          if (name.isNotEmpty && name != '空白') {
            names.add(name);
          }
        }
      }
      return names.toList();
    } catch (e) {
      debugPrint('Error fetching project names: $e');
      return [];
    }
  }

  Future<DailyRecord?> getLatestRecord(String projectName) async {
    await _ensureSheetsApi();
    if (_sheetsApi == null) return null;

    try {
      final response = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        '$_activeSheetName!A:P',
      );

      if (response.values == null || response.values!.length <= 1) return null;

      for (int i = response.values!.length - 1; i >= 1; i--) {
        final row = response.values![i];
        if (row.length > 2 && row[2].toString().trim() == projectName) {
          return DailyRecord.fromRow(row);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching latest record: $e');
      return null;
    }
  }

  Future<bool> appendRecord(DailyRecord record) async {
    await _ensureSheetsApi();
    if (_sheetsApi == null) return false;

    try {
      await ensureHeaders();

      final valueRange = ValueRange.fromJson({
        'values': [record.toRow()],
      });

      await _sheetsApi!.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        '$_activeSheetName!A1',
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );
      return true;
    } catch (e) {
      debugPrint('Error appending record: $e');
      return false;
    }
  }

  static String get spreadsheetUrl =>
      'https://docs.google.com/spreadsheets/d/$spreadsheetId';
}
