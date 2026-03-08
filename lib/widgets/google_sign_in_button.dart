// 根據平台自動選擇實作：
// - Web：使用官方 Google Sign-In 按鈕 (renderButton)
// - 其他平台：回傳空 widget（不會被使用到）
export 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart';
