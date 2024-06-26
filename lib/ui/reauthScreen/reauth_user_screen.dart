import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/show_toast_dailog.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;

import '../../main.dart';

enum AuthProviders { PASSWORD, PHONE, FACEBOOK, APPLE }

class ReAuthUserScreen extends StatefulWidget {
  final AuthProviders provider;
  final String? email;
  final String? phoneNumber;
  final bool deleteUser;

  ReAuthUserScreen({Key? key, required this.provider, this.email, this.phoneNumber, required this.deleteUser}) : super(key: key);

  @override
  _ReAuthUserScreenState createState() => _ReAuthUserScreenState();
}

class _ReAuthUserScreenState extends State<ReAuthUserScreen> {
  TextEditingController _passwordController = TextEditingController();
  late Widget body = CircularProgressIndicator.adaptive(
    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
  );
  String? _verificationID;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      buildBody();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Text(
                  "Re-AuthenticateToAction".tr(),
                  textAlign: TextAlign.center,
                ),
              ),
              body,
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(hintText: 'Password'.tr()),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(COLOR_PRIMARY),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(12),
                ),
              ),
            ),
            onPressed: () async => passwordButtonPressed(),
            child: Text(
              'Verify'.tr(),
              style: TextStyle(color: isDarkMode(context) ? Colors.black : Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildFacebookButton() {
    return ElevatedButton.icon(
      label: Expanded(
        child: Text(
          'Facebook Verify'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Image.asset(
          'assets/images/facebook_logo.png',
          color: Colors.white,
          height: 30,
          width: 30,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(FACEBOOK_BUTTON_COLOR),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: Color(FACEBOOK_BUTTON_COLOR),
          ),
        ),
      ),
      onPressed: () async => facebookButtonPressed(),
    );
  }

  Widget buildAppleButton() {
    return FutureBuilder<bool>(
      future: apple.TheAppleSignIn.isAvailable(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
          );
        }
        if (!snapshot.hasData || (snapshot.data != true)) {
          return Center(child: Text("Apple Sign is Not Available".tr()));
        } else {
          return apple.AppleSignInButton(
            cornerRadius: 12.0,
            type: apple.ButtonType.continueButton,
            style: isDarkMode(context) ? apple.ButtonStyle.white : apple.ButtonStyle.black,
            onPressed: () => appleButtonPressed(),
          );
        }
      },
    );
  }

  Widget buildPhoneField() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: PinCodeTextField(
            length: 6,
            appContext: context,
            keyboardType: TextInputType.phone,
            backgroundColor: Colors.transparent,
            pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(5),
                fieldHeight: 40,
                fieldWidth: 40,
                activeColor: Color(COLOR_PRIMARY),
                activeFillColor: isDarkMode(context) ? Colors.grey.shade700 : Colors.grey.shade100,
                selectedFillColor: Colors.transparent,
                selectedColor: Color(COLOR_PRIMARY),
                inactiveColor: Colors.grey.shade600,
                inactiveFillColor: Colors.transparent),
            enableActiveFill: true,
            onCompleted: (v) {
              _submitCode(v);
            },
            onChanged: (value) {
              print(value);
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  passwordButtonPressed() async {
    if (_passwordController.text.isEmpty) {
      showAlertDialog(
        context,
        'Empty Password'.tr(),
        'Password is required to update email'.tr(),
        true,
      );
    } else {
       ShowToastDialog.showLoader('Verifying...'.tr());
      try {
        auth.UserCredential? result = await FireStoreUtils.reAuthUsers(widget.provider, email: MyAppState.currentUser!.email, password: _passwordController.text);
        if (result == null) {
          ShowToastDialog.closeLoader();
          showAlertDialog(
            context,
            "Couldn't verify".tr(),
            'Please double check the password and try again.'.tr(),
            true,
          );
        } else {
          if (result.user != null) {
            if (widget.email != null) {
              await result.user!.updateEmail(widget.email!);
            }
            result.user!.delete();
            ShowToastDialog.closeLoader();
            Navigator.pop(context, true);
          } else {
            ShowToastDialog.closeLoader();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Couldn't verify, Please try again.".tr(),
                  style: TextStyle(fontSize: 17),
                ),
              ),
            );
          }
        }
      } catch (e, s) {
        print('_ReAuthUserScreenState.passwordButtonPressed $e $s');
        ShowToastDialog.closeLoader();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Couldn't verify, Please try again.".tr(),
              style: TextStyle(fontSize: 17),
            ),
          ),
        );
      }
    }
  }

  facebookButtonPressed() async {
    try {
      ShowToastDialog.showLoader('Verifying...'.tr());
      AccessToken? token;
      FacebookAuth facebookAuth = FacebookAuth.instance;
      if (await facebookAuth.accessToken == null) {
        LoginResult result = await facebookAuth.login();
        if (result.status == LoginStatus.success) {
          token = await facebookAuth.accessToken;
        }
      } else {
        token = await facebookAuth.accessToken;
      }
      if (token != null) await FireStoreUtils.reAuthUsers(widget.provider, accessToken: token);
      ShowToastDialog.closeLoader();
      Navigator.pop(context, true);
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      print('facebookButtonPressed $e $s');
      showAlertDialog(
        context,
        'Error',
        "Couldn't verify".tr() + ' ' + 'with facebook.'.tr(),
        true,
      );
    }
  }

  appleButtonPressed() async {
    try {
      ShowToastDialog.showLoader('Verifying...'.tr());
      final appleCredential = await apple.TheAppleSignIn.performRequests([
        apple.AppleIdRequest(requestedScopes: [apple.Scope.email, apple.Scope.fullName])
      ]);
      if (appleCredential.error != null) {
        showAlertDialog(
          context,
          'Error',
          "Couldn't verify".tr() + ' ' + "with apple.".tr(),
          true,
        );
      }
      if (appleCredential.status == apple.AuthorizationStatus.authorized) {
        await FireStoreUtils.reAuthUsers(widget.provider, appleCredential: appleCredential);
      }
      ShowToastDialog.closeLoader();
      Navigator.pop(context, true);
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      print('appleButtonPressed $e $s');
      showAlertDialog(
        context,
        'Error',
        "Couldn't verify".tr() + ' ' + "with apple.".tr(),
        true,
      );
    }
  }

  _submitPhoneNumber() async {
    ShowToastDialog.showLoader('Sending code...'.tr());
    await FireStoreUtils.firebaseSubmitPhoneNumber(
      widget.phoneNumber!,
      (String verificationId) {
        if (mounted) {
          ShowToastDialog.closeLoader();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Code verification timeout, request new code.".tr(),
              ),
            ),
          );
        }
      },
      (String? verificationId, int? forceResendingToken) async {
        print('_ReAuthUserScreenState._submitPhoneNumber $verificationId');
        if (mounted) {
          print('_ReAuthUserScreenState.mounted');
          ShowToastDialog.closeLoader();
          _verificationID = verificationId;
        }
      },
      (auth.FirebaseAuthException error) async {
        if (mounted) {
          ShowToastDialog.closeLoader();
          print('${error.message} ${error.stackTrace}');
          String message = "errorTryAgain".tr();
          switch (error.code) {
            case 'invalid-verification-code':
              message = 'Invalid code or has been expired.'.tr();
              break;
            case 'user-disabled':
              message = 'This user has been disabled.'.tr();
              break;
            default:
              message = "An error has occurred, please try again.".tr();
              break;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
              ),
            ),
          );
          Navigator.pop(context);
        }
      },
      (auth.PhoneAuthCredential credential) async {
        print('_ReAuthUserScreenState._submitPhoneNumber');
      },
    );
  }

  void _submitCode(String code) async {
    ShowToastDialog.showLoader('Verifying...'.tr());
    try {
      if (_verificationID != null) {
        if (widget.deleteUser) {
          await FireStoreUtils.reAuthUsers(widget.provider, verificationId: _verificationID!, smsCode: code);
        } else {
          auth.PhoneAuthCredential credential = auth.PhoneAuthProvider.credential(smsCode: code, verificationId: _verificationID!);
          await auth.FirebaseAuth.instance.currentUser!.updatePhoneNumber(credential);
        }
        ShowToastDialog.closeLoader();
        Navigator.pop(context, true);
      } else {
        ShowToastDialog.closeLoader();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error has occurred, please try again.".tr()),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } on auth.FirebaseAuthException catch (exception) {
      print('_ReAuthUserScreenState._submitCode ${exception.toString()}');
      ShowToastDialog.closeLoader();
      Navigator.pop(context);

      String message = "An error has occurred, please try again.".tr();
      switch (exception.code) {
        case 'invalid-verification-code':
          message = 'Invalid code or has been expired.'.tr();
          break;
        case 'user-disabled':
          message = 'This user has been disabled.'.tr();
          break;
        default:
          message = "An error has occurred, please try again.".tr();
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
        ),
      );
    } catch (e, s) {
      print('_PhoneNumberInputScreenState._submitCode $e $s');
      ShowToastDialog.closeLoader();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "An error has occurred, please try again.".tr(),
          ),
        ),
      );
    }
  }

  void buildBody() async {
    switch (widget.provider) {
      case AuthProviders.PASSWORD:
        body = buildPasswordField();
        break;
      case AuthProviders.PHONE:
        await _submitPhoneNumber();
        body = buildPhoneField();
        break;
      case AuthProviders.FACEBOOK:
        body = buildFacebookButton();
        break;
      case AuthProviders.APPLE:
        body = buildAppleButton();
        break;
    }
    setState(() {});
  }
}
