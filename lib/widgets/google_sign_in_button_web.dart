// Web 平台實作：使用 google_sign_in_web 的官方 renderButton
import 'package:flutter/widgets.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

Widget buildGoogleSignInButton() =>
    (GoogleSignInPlatform.instance as GoogleSignInPlugin).renderButton();
