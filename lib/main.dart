import 'dart:async';
import 'dart:developer';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/firebase_options.dart';
import 'package:emartstore/model/User.dart';
import 'package:emartstore/model/mail_setting.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/services/notification_service.dart';
import 'package:emartstore/ui/auth/AuthScreen.dart';
import 'package:emartstore/ui/container/ContainerScreen.dart';
import 'package:emartstore/ui/onBoarding/OnBoardingScreen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  SharedPreferences sp = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
        supportedLocales: [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: sp.getString('languageCode') != null ? Locale(sp.getString('languageCode')!) : Locale('en'),
        useFallbackTranslations: true,
        saveLocale: true,
        useOnlyLangCode: true,
        child: MyApp()),
  );
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static User? currentUser;

  static AudioPlayer audioPlayer = AudioPlayer(playerId: "playerId");

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    audioPlayer.stop();
    print("0000000000--------->${MyAppState.audioPlayer.state}");
  }

  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      /// Wait for Firebase to initialize and set `_initialized` state to true
      print("initializeFlutterFire111");
      FirebaseFirestore.instance.collection(Setting).doc("globalSettings").get().then((dineinresult) {
        if (dineinresult.exists && dineinresult.data() != null && dineinresult.data()!.containsKey("website_color")) {
          COLOR_PRIMARY = int.parse(dineinresult.data()!["website_color"].replaceFirst("#", "0xff"));
        }
      });
      await FirebaseFirestore.instance.collection(Setting).doc("emailSetting").get().then((value) {
        if (value.exists) {
          mailSettings = MailSettings.fromJson(value.data()!);
        }
      });
      await FirebaseFirestore.instance.collection(Setting).doc("Version").get().then((value) {
        print(value.data());
        appVersion = value.data()!['app_version'].toString();
      });
      await FirebaseFirestore.instance.collection(Setting).doc("googleMapKey").get().then((value) {
        print(value.data());
        GOOGLE_API_KEY = value.data()!['key'].toString();
      });

      await FirebaseFirestore.instance.collection(Setting).doc("notification_setting").get().then((value) {
        print(value.data());
        senderId = value.data()!['senderId'].toString();
        jsonNotificationFileURL = value.data()!['serviceJson'].toString();
      });
    } catch (e) {
      setState(() {
        print(e.toString() + "==========ERROR");
      });
    }
  }

  NotificationService notificationService = NotificationService();

  notificationInit() {
    notificationService.initInfo().then((value) async {
      String token = await NotificationService.getToken();
      log(":::::::TOKEN:::::: $token");
      if (currentUser != null) {
        await FireStoreUtils.getCurrentUser(currentUser!.userID).then((value) {
          if (value != null) {
            currentUser = value;
            currentUser!.fcmToken = token;
            FireStoreUtils.updateCurrentUser(currentUser!);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: notificationService.navigatorKey,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        title: 'Store Dashboard'.tr(),
        builder: EasyLoading.init(),
        theme: ThemeData(
            bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.white),
            primaryColor: Color(COLOR_PRIMARY),
            brightness: Brightness.light,
            textSelectionTheme: TextSelectionThemeData(selectionColor: Colors.black),
            appBarTheme: AppBarTheme(
                centerTitle: true,
                titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
                color: Colors.transparent,
                elevation: 0,
                actionsIconTheme: IconThemeData(color: Color(COLOR_PRIMARY)),
                iconTheme: IconThemeData(color: Color(COLOR_PRIMARY)))),
        darkTheme: ThemeData(
            bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.grey.shade900),
            primaryColor: Color(COLOR_PRIMARY),
            brightness: Brightness.dark,
            textSelectionTheme: TextSelectionThemeData(selectionColor: Colors.white),
            appBarTheme: AppBarTheme(
                centerTitle: true,
                titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                color: Colors.transparent,
                elevation: 0,
                actionsIconTheme: IconThemeData(color: Color(COLOR_PRIMARY)),
                iconTheme: IconThemeData(color: Color(COLOR_PRIMARY)))),
        debugShowCheckedModeBanner: false,
        color: Color(COLOR_PRIMARY),
        home: OnBoarding());
  }

  @override
  void initState() {
    notificationInit();
    initializeFlutterFire();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class OnBoarding extends StatefulWidget {
  @override
  State createState() {
    return OnBoardingState();
  }
}

class OnBoardingState extends State<OnBoarding> {
  Future hasFinishedOnBoarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool finishedOnBoarding = (prefs.getBool(FINISHED_ON_BOARDING) ?? false);

    if (finishedOnBoarding) {
      auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        User? user = await FireStoreUtils.getCurrentUser(firebaseUser.uid);
        if (user != null && user.role == USER_ROLE_VENDOR) {
          if (user.active == true) {
            user.active = true;
            user.role = USER_ROLE_VENDOR;
            FireStoreUtils.firebaseMessaging.getToken().then((value) async {
              user.fcmToken = value!;
              await FireStoreUtils.firestore.collection(USERS).doc(user.userID).update({"fcmToken": user.fcmToken});
              if (user.vendorID.isNotEmpty) {
                await FireStoreUtils.firestore.collection(VENDORS).doc(user.vendorID).update({"fcmToken": value});
              }
            });
            MyAppState.currentUser = user;
            pushReplacement(context, new ContainerScreen(user: user));
          } else {
            user.lastOnlineTimestamp = Timestamp.now();
            await FireStoreUtils.firestore.collection(USERS).doc(user.userID).update({"fcmToken": ""});
            if (user.vendorID.isNotEmpty) {
              await FireStoreUtils.firestore.collection(VENDORS).doc(user.vendorID).update({"fcmToken": ""});
            }
            // await FireStoreUtils.updateCurrentUser(user);
            await auth.FirebaseAuth.instance.signOut();
            await FacebookAuth.instance.logOut();
            MyAppState.currentUser = null;
            pushReplacement(context, new AuthScreen());
          }
        } else {
          pushReplacement(context, new AuthScreen());
        }
      } else {
        pushReplacement(context, new AuthScreen());
      }
    } else {
      pushReplacement(context, new OnBoardingScreen());
    }
  }

  @override
  void initState() {
    super.initState();
    hasFinishedOnBoarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
