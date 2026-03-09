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
  String? _lastError;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? webClientId : null,
      scopes: _scopes,
    );

    _googleSignIn.onCurrentUserChanged.listen((account) async {
      _isSignedIn = account != null;
      _userName = account?.displayName;
      if (account != null) {
        await _ensureSheetsApi();
      } else {
        _sheetsApi = null;
      }
      notifyListeners();
    });

    // 嘗試靜默登入，但不觸發任何彈窗
    try {
      await _googleSignIn.signInSilently();
    } catch (_) {}
  }

  Future<bool> signIn() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // 在 Web 版，直接透過 signIn 請求所有 scopes 是最穩定的
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _lastError = '登入失敗或已取消';
        return false;
      }
      
      // 檢查是否真的拿到了權限
      final hasScopes = await _googleSignIn.canAccessScopes(_scopes);
      if (!hasScopes) {
        // 如果沒拿到，不自動補抓（避免閃現），直接提示用戶
        _lastError = '請重新登入並務必「勾選」試算表讀寫權限';
        await _googleSignIn.signOut();
        return false;
      }

      await _ensureSheetsApi();
      return _isSignedIn;
    } catch (e) {
      _lastError = '登入發生錯誤: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 強制重新授權登入
  Future<bool> forceSignIn() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 先登出以清除快取
      await _googleSignIn.signOut();
      
      // 使用 prompt: 'consent' 強制顯示授權畫面
      final account = await _googleSignIn.signInSilently(reAuthenticate: true)
          .catchError((_) => _googleSignIn.signIn()); // 這裡 google_sign_in 插件在 web 版行為略有不同
      
      // 如果是一般 signIn，Web 版可以透過重新建立 GoogleSignIn 物件來達成，
      // 但更直接的方法通常是讓用戶去 google 帳號權限頁面移除。
      // 這裡我們嘗試最核心的重新登入
      final retryAccount = await _googleSignIn.signIn();
      
      if (retryAccount == null) return false;
      await _ensureSheetsApi();
      return _isSignedIn;
    } catch (e) {
      _lastError = 'Force sign in error: $e';
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
    _lastError = null;

    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        _lastError = '用戶未登入';
        return;
      }

      // 檢查是否擁有必要權限
      final hasScopes = await _googleSignIn.canAccessScopes(_scopes);
      if (!hasScopes) {
        debugPrint('Missing required scopes, requesting...');
        _lastError = '缺少試算表讀寫權限，正在嘗試重新獲取...';
        // 在 Web 版上，這通常需要用戶手動觸發權限。
        // 我們先嘗試靜默獲取，如果不行，至少紀錄這個狀態。
        final success = await _googleSignIn.requestScopes(_scopes);
        if (!success) {
          _lastError = '授權失敗：請確保在登入時勾選了權限。';
          return;
        }
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        _lastError = '無法取得授權客戶端，請嘗試登出後重新登入。';
        return;
      }
      _sheetsApi = SheetsApi(authClient);
      await _detectActiveSheet();
      await ensureHeaders();
    } catch (e) {
      _lastError = '權限驗證過程發生錯誤: $e';
      debugPrint(_lastError);
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
        debugPrint('Sheet "$name" not found or error: $e');
        // 如果錯誤不是範圍錯誤 (可能是 ID 錯或沒開 API)，就在此紀錄
        if (!e.toString().contains('range')) {
           _lastError = '存取試算表失敗，請檢查 ID 是否正確且 Google Sheets API 已開啟';
        }
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
      _lastError = '儲存紀錄失敗: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  static String get spreadsheetUrl =>
      'https://docs.google.com/spreadsheets/d/$spreadsheetId';
}
