import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart' as easyLocal;
import 'package:emartstore/constants.dart';
import 'package:emartstore/main.dart';
import 'package:emartstore/model/User.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/show_toast_dailog.dart';
import 'package:emartstore/ui/container/ContainerScreen.dart';
import 'package:emartstore/ui/phoneAuth/PhoneNumberInputScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

File? _image;

class SignUpScreen extends StatefulWidget {
  @override
  State createState() => _SignUpState();
}

class _SignUpState extends State<SignUpScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  TextEditingController _passwordController = new TextEditingController();
  GlobalKey<FormState> _key = new GlobalKey();
  String? firstName, lastName, email, mobile, password, confirmPassword;
  AutovalidateMode _validate = AutovalidateMode.disabled;

  @override
  void initState() {
    // TODO: implement initState
    getData();
    super.initState();
  }

  bool? auto_approve_vendor = false;

  getData() async {
    await FirebaseFirestore.instance.collection(Setting).doc('vendor').get().then((value) {
      setState(() {
        auto_approve_vendor = value.data()!['auto_approve_vendor'];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      retrieveLostData();
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDarkMode(context) ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        child: new Container(
          margin: new EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
          child: new Form(
            key: _key,
            autovalidateMode: _validate,
            child: formUI(),
          ),
        ),
      ),
    );
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse? response = await _imagePicker.retrieveLostData();
    if (response == null) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _image = File(response.file!.path);
      });
    }
  }

  _onCameraClick() {
    final action = CupertinoActionSheet(
      message: Text(
        'Add profile picture',
        style: TextStyle(fontSize: 15.0),
      ).tr(),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text('Choose from gallery').tr(),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
            if (image != null)
              setState(() {
                _image = File(image.path);
              });
          },
        ),
        CupertinoActionSheetAction(
          child: Text('Take a picture').tr(),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
            if (image != null)
              setState(() {
                _image = File(image.path);
              });
          },
        ),
        CupertinoActionSheetAction(
          child: Text('Remove picture').tr(),
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.pop(context);
            setState(() {
              _image = null;
            });
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text('Cancel').tr(),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  Widget formUI() {
    return new Column(
      children: <Widget>[
        new Align(
            alignment: Directionality.of(context) == TextDirection.ltr ? Alignment.topLeft : Alignment.topRight,
            child: Text(
              'Create new account'.tr(),
              style: TextStyle(color: Color(COLOR_PRIMARY), fontWeight: FontWeight.bold, fontSize: 25.0),
            ).tr()),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 32, right: 8, bottom: 8),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade400,
                child: ClipOval(
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: _image == null
                        ? Image.asset(
                            'assets/images/placeholder.jpg',
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            _image!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              Positioned(
                left: 45,
                child: InkWell(
                  onTap: () {
                    _onCameraClick();
                  },
                  child: ClipOval(
                    child: Container(
                      color: Color(COLOR_PRIMARY),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          CupertinoIcons.camera,
                          size: 20,
                          color: isDarkMode(context) ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20.0, right: 8.0, left: 8.0),
          child: TextFormField(
            cursorColor: Color(COLOR_PRIMARY),
            textAlignVertical: TextAlignVertical.center,
            validator: validateName,
            onSaved: (String? val) {
              firstName = val;
            },
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              contentPadding: new EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              fillColor: Colors.white,
              hintText: 'First Name'.tr(),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(25.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(25.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0, right: 8.0, left: 8.0),
          child: TextFormField(
            validator: validateName,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: Color(COLOR_PRIMARY),
            onSaved: (String? val) {
              lastName = val;
            },
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              contentPadding: new EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              fillColor: Colors.white,
              hintText: 'Last Name'.tr(),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(25.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(25.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0, right: 8.0, left: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), shape: BoxShape.rectangle, border: Border.all(color: Colors.grey.shade400)),
            child: InternationalPhoneNumberInput(
              onInputChanged: (value) {
                mobile = "${value.phoneNumber}";
              },
              ignoreBlank: true,
              autoValidateMode: AutovalidateMode.onUserInteraction,
              inputDecoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                hintText: 'Phone Number'.tr(),
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                errorBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
              inputBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              initialValue: PhoneNumber(isoCode: 'US'),
              selectorConfig: const SelectorConfig(selectorType: PhoneInputSelectorType.DIALOG),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0, right: 8.0, left: 8.0),
          child: TextFormField(
            keyboardType: TextInputType.emailAddress,
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.next,
            cursorColor: Color(COLOR_PRIMARY),
            validator: validateEmail,
            onSaved: (String? val) {
              email = val;
            },
            decoration: InputDecoration(
              contentPadding: new EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              fillColor: Colors.white,
              hintText: 'Email Address'.tr(),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(25.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(25.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0, right: 8.0, left: 8.0),
          child: TextFormField(
            obscureText: true,
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.next,
            controller: _passwordController,
            validator: validatePassword,
            onSaved: (String? val) {
              password = val;
            },
            style: TextStyle(fontSize: 18.0),
            cursorColor: Color(COLOR_PRIMARY),
            decoration: InputDecoration(
              contentPadding: new EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              fillColor: Colors.white,
              hintText: 'Password'.tr(),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(25.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(25.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0, right: 8.0, left: 8.0),
          child: TextFormField(
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _signUpWithEmailAndPassword(),
            obscureText: true,
            validator: (val) => validateConfirmPassword(_passwordController.text, val),
            onSaved: (String? val) {
              confirmPassword = val;
            },
            style: TextStyle(fontSize: 18.0),
            cursorColor: Color(COLOR_PRIMARY),
            decoration: InputDecoration(
              contentPadding: new EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              fillColor: Colors.white,
              hintText: 'Confirm Password'.tr(),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(25.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(25.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 50.0, left: 50.0, top: 20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(COLOR_PRIMARY),
                padding: EdgeInsets.only(top: 12, bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  side: BorderSide(
                    color: Color(COLOR_PRIMARY),
                  ),
                ),
              ),
              onPressed: () => _signUpWithEmailAndPassword(),
              child: Text(
                'Sign Up'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'OR',
              style: TextStyle(color: isDarkMode(context) ? Colors.white : Colors.black),
            ).tr(),
          ),
        ),
        InkWell(
          onTap: () {
            push(context, PhoneNumberInputScreen(login: false));
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.white, border: Border.all(color: Color(COLOR_PRIMARY), width: 1)),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.call,
                    color: Color(COLOR_PRIMARY),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Sign up with phone number'.tr(),
                    style: TextStyle(color: Color(COLOR_PRIMARY), fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  /// dispose text controllers to avoid memory leaks
  @override
  void dispose() {
    _passwordController.dispose();
    _image = null;
    super.dispose();
  }

  /// if the fields are validated and location is enabled we create a new user
  /// and navigate to [ContainerScreen] else we show error
  _signUpWithEmailAndPassword() async {
    if (_key.currentState?.validate() ?? false) {
      _key.currentState!.save();
      if (mobile != null) {
        ShowToastDialog.showLoader('Creating new account, Please wait...'.tr());
        dynamic result = await FireStoreUtils.firebaseSignUpWithEmailAndPassword(email!.trim(), password!.trim(), _image, firstName!, lastName!, mobile!, auto_approve_vendor);
        await ShowToastDialog.closeLoader();
        if (result != null && result is User) {
          if (auto_approve_vendor == true) {
            MyAppState.currentUser = result;
            if (result.vendorID.isNotEmpty) {
              await FireStoreUtils.firestore.collection(VENDORS).doc(result.vendorID).update({"fcmToken": result.fcmToken});
            }
            pushAndRemoveUntil(context, ContainerScreen(user: result), false);
          } else {
            showAlertDialog(context, 'Signup Successfully'.tr(), "Thank you for sign up, your application is under approval so please wait till that approve.".tr(), true, login: true);
          }
        } else if (result != null && result is String) {
          showAlertDialog(context, 'Failed'.tr(), result, true);
        } else {
          showAlertDialog(context, 'Failed'.tr(), "Couldn't sign up".tr(), true);
        }
      } else {
        final snack = SnackBar(
          content: Text(
            'Phone number is Empty'.tr(),
            style: TextStyle(color: Colors.white),
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        );
        ScaffoldMessenger.of(context).showSnackBar(snack);
      }
    } else {
      setState(() {
        _validate = AutovalidateMode.onUserInteraction;
      });
    }
  }
}
