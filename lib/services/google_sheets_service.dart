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
  static const String sheetName = 'Sheet1';

  static const List<String> _scopes = [
    SheetsApi.spreadsheetsScope,
  ];

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  String? _userName;
  String? get userName => _userName;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SheetsApi? _sheetsApi;
  bool _initialized = false;
  GoogleSignInAccount? _currentUser;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      clientId: webClientId,
    );

    googleSignIn.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          _currentUser = event.user;
          _isSignedIn = true;
          _userName = event.user.displayName;
          _sheetsApi = null; // Reset so it gets re-created with new user
          notifyListeners();
        case GoogleSignInAuthenticationEventSignOut():
          _currentUser = null;
          _isSignedIn = false;
          _userName = null;
          _sheetsApi = null;
          notifyListeners();
      }
    });

    // Try silent sign-in
    googleSignIn.attemptLightweightAuthentication();
  }

  Future<bool> signIn() async {
    _isLoading = true;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn.instance;
      _currentUser = await googleSignIn.authenticate(scopeHint: _scopes);
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
    await GoogleSignIn.instance.signOut();
    _sheetsApi = null;
    _currentUser = null;
  }

  Future<void> _ensureSheetsApi() async {
    if (_sheetsApi != null) return;
    if (_currentUser == null) return;

    try {
      // Try silent authorization first
      GoogleSignInClientAuthorization? authorization = await _currentUser!
          .authorizationClient
          .authorizationForScopes(_scopes);

      // If that fails, request with user interaction
      authorization ??= await _currentUser!
          .authorizationClient
          .authorizeScopes(_scopes);

      // Use extension method to get AuthClient from GoogleSignInClientAuthorization
      final authClient = authorization.authClient(scopes: _scopes);
      _sheetsApi = SheetsApi(authClient);

      // 連線後立即確認欄位標題是否存在
      await ensureHeaders();
    } catch (e) {
      debugPrint('Error creating Sheets API client: $e');
    }
  }

  Future<void> ensureHeaders() async {
    await _ensureSheetsApi();
    if (_sheetsApi == null) return;

    try {
      final response = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        '$sheetName!A1:P1',
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
          '$sheetName!A1:P1',
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
        '$sheetName!C:C',
      );

      if (response.values == null) return [];

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
        '$sheetName!A:P',
      );

      if (response.values == null || response.values!.length <= 1) return null;

      // Find the last row matching the project name
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
        '$sheetName!A1',
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
