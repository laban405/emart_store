import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartstore/constants.dart';
import 'package:emartstore/main.dart';
import 'package:emartstore/model/CurrencyModel.dart';
import 'package:emartstore/model/SectionModel.dart';
import 'package:emartstore/model/User.dart';
import 'package:emartstore/model/VendorModel.dart';
import 'package:emartstore/services/FirebaseHelper.dart';
import 'package:emartstore/services/helper.dart';
import 'package:emartstore/ui/DineIn/DineInRequest.dart';
import 'package:emartstore/ui/Language/language_choose_screen.dart';
import 'package:emartstore/ui/addDineIn/AddDineIn.dart';
import 'package:emartstore/ui/add_store/add_store.dart';
import 'package:emartstore/ui/add_story_screen.dart';
import 'package:emartstore/ui/auth/AuthScreen.dart';
import 'package:emartstore/ui/bank_details/bank_details_Screen.dart';
import 'package:emartstore/ui/chat_screen/inbox_screen.dart';
import 'package:emartstore/ui/manageProductsScreen/ManageProductsScreen.dart';
import 'package:emartstore/ui/offer/offers.dart';
import 'package:emartstore/ui/ordersScreen/OrdersScreen.dart';
import 'package:emartstore/ui/privacy_policy/privacy_policy.dart';
import 'package:emartstore/ui/profile/ProfileScreen.dart';
import 'package:emartstore/ui/special_offer_screen/SpecialOfferScreen.dart';
import 'package:emartstore/ui/termsAndCondition/terms_and_codition.dart';
import 'package:emartstore/ui/wallet/walletScreen.dart';
import 'package:emartstore/working_hour/working_hours_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum DrawerSelection {
  Orders,
  DineIn,
  DineInReq,
  SpecialOffer,
  WorkingHours,
  ManageProducts,
  addStory,
  AddRestauarnt,
  Offers,
  Profile,
  Wallet,
  BankInfo,
  chooseLanguage,
  termsCondition,
  privacyPolicy,
  inbox,
  Logout
}

class ContainerScreen extends StatefulWidget {
  final User? user;

  final Widget currentWidget;
  final String appBarTitle;
  final DrawerSelection drawerSelection;
  String? userId = "";
  bool? isDineInReq = false;

  ContainerScreen({Key? key, this.user, this.userId, this.isDineInReq, appBarTitle, currentWidget, this.drawerSelection = DrawerSelection.Orders})
      : this.appBarTitle = appBarTitle ?? 'Orders'.tr(),
        this.currentWidget = currentWidget ?? OrdersScreen(),
        super(key: key);

  @override
  _ContainerScreen createState() {
    return _ContainerScreen();
  }
}

class _ContainerScreen extends State<ContainerScreen> {
  late String _appBarTitle;
  final fireStoreUtils = FireStoreUtils();
  // Widget _currentWidget = OrdersScreen();
  // DrawerSelection _drawerSelection = DrawerSelection.Orders;
  late Widget _currentWidget;
  late DrawerSelection _drawerSelection;
  VendorModel? vendorModel;
  final audioPlayer = AudioPlayer(playerId: "playerId");
  SectionModel? selectedModel;

  @override
  void initState() {
    super.initState();
    setCurrency();
    //user = widget.user;

    FireStoreUtils.getCurrentUser(MyAppState.currentUser == null ? widget.userId! : MyAppState.currentUser!.userID).then((value) {
      setState(() {
        MyAppState.currentUser = value;
      });
    });
    getLanguages();
    getSpecialDiscount();
    if (MyAppState.currentUser!.vendorID.isNotEmpty) {
      FireStoreUtils.getVendor(MyAppState.currentUser!.vendorID)?.then((value) {
        if (value != null) {
          vendorModel = value;
          getCategory();
          FireStoreUtils.getDineStatus(vendorModel!.section_id).then((value) async {
            if (vendorModel!.dine_in_active != value) {
              vendorModel!.dine_in_active = value;
              await FirebaseFirestore.instance.collection(VENDORS).doc(vendorModel!.id).update({"dine_in_active": value});
            }
            setState(() {});
          });
        }
      });
    }
    //getKeyHash();

    //   _appBarTitle = 'Orders'.tr();
    _currentWidget = widget.currentWidget;
    _appBarTitle = widget.appBarTitle;
    _drawerSelection = widget.drawerSelection;

    fireStoreUtils.getplaceholderimage();
    // print(MyAppState.currentUser!.vendorID);

    /// On iOS, we request notification permissions, Does nothing and returns null on Android
    FireStoreUtils.firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  getCategory() async {
    await FireStoreUtils.getSectionsById(vendorModel!.section_id).then((value) {
      setState(() {
        selectedModel = value;
      });
    });
  }

  bool specialDiscountEnable = false;
  bool storyEnable = false;

  getSpecialDiscount() async {
    await FirebaseFirestore.instance.collection(Setting).doc('specialDiscountOffer').get().then((value) {
      specialDiscountEnable = value.data()!['isEnable'];
    });
    await FirebaseFirestore.instance.collection(Setting).doc('story').get().then((value) {
      storyEnable = value.data()!['isEnabled'];
    });
    await FirebaseFirestore.instance.collection(Setting).doc('digitalProduct').get().then((value) {
      fileSize = value.data()!['fileSize'];
    });
    setState(() {});
  }

  setCurrency() async {
    /*await FireStoreUtils().getCurrency().then((value) {
      for (var element in value) {
        if (element.isactive = true) {
          setState(() {
            currencyData = element;
          });
        }
      }
    });*/
    await FireStoreUtils().getCurrency().then((value) {
      if (value != null) {
        currencyData = value;
      } else {
        currencyData = CurrencyModel(id: "", code: "USD", decimal: 2, isactive: true, name: "US Dollar", symbol: "\$", symbolatright: false);
      }
    });
  }

  DateTime pre_backpress = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: _drawerSelection == DrawerSelection.Wallet ? true : false,
      backgroundColor: isDarkMode(context) ? Color(COLOR_DARK) : null,
      drawer: Drawer(
          child: Container(
        color: isDarkMode(context) ? Color(COLOR_DARK) : null,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  MyAppState.currentUser == null
                      ? Container()
                      : DrawerHeader(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              displayCircleImage(MyAppState.currentUser!.profilePictureURL, 60, false),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  MyAppState.currentUser!.fullName(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              Text(
                                MyAppState.currentUser!.email,
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          decoration: BoxDecoration(
                            color: Color(COLOR_PRIMARY),
                          ),
                        ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.Orders,
                      title: Text('Orders').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(
                          () {
                            _drawerSelection = DrawerSelection.Orders;
                            _appBarTitle = 'Orders'.tr();
                            _currentWidget = OrdersScreen();
                          },
                        );
                      },
                      leading: Image.asset(
                        'assets/images/order.png',
                        color: _drawerSelection == DrawerSelection.Orders
                            ? Color(COLOR_PRIMARY)
                            : isDarkMode(context)
                                ? Colors.grey.shade200
                                : Colors.grey.shade600,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: vendorModel != null && vendorModel!.dine_in_active,
                    child: ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.DineInReq,
                        title: Text('Dine-in Requests').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(
                            () {
                              _drawerSelection = DrawerSelection.DineInReq;
                              _appBarTitle = 'Dine-in Requests'.tr();
                              _currentWidget = DineInRequest();
                            },
                          );
                        },
                        leading: Icon(Icons.restaurant_menu),
                      ),
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.AddRestauarnt,
                      leading: Icon(Icons.restaurant_outlined),
                      title: Text('Add Store').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.AddRestauarnt;
                          _appBarTitle = 'Add Store'.tr();
                          _currentWidget = AddStoreScreen();
                        });
                      },
                    ),
                  ),
                  Visibility(
                    visible: vendorModel != null && vendorModel!.dine_in_active,
                    child: ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.DineIn,
                        leading: Icon(Icons.restaurant_outlined),
                        title: Text('Dine-in').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.DineIn;
                            _appBarTitle = 'Dine-in'.tr();
                            _currentWidget = AddDineIn();
                          });
                        },
                      ),
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.ManageProducts,
                      leading: FaIcon(FontAwesomeIcons.pizzaSlice),
                      title: Text('Manage Products').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.ManageProducts;
                          _appBarTitle = 'Your Products'.tr();
                          _currentWidget = ManageProductsScreen();
                        });
                      },
                    ),
                  ),
                  Visibility(
                    visible: storyEnable == true && (selectedModel != null && selectedModel!.serviceTypeFlag != "ecommerce-service") ? true : false,
                    child: ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.addStory,
                        leading: Icon(Icons.ad_units),
                        title: Text('Add Story').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            if (MyAppState.currentUser!.vendorID.isNotEmpty) {
                              _drawerSelection = DrawerSelection.addStory;
                              _appBarTitle = 'Add Story'.tr();
                              _currentWidget = AddStoryScreen();
                            } else {
                              final snackBar = SnackBar(
                                content: const Text('Please add restaurant first.'),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  Visibility(
                    visible: specialDiscountEnable,
                    child: ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.SpecialOffer,
                        leading: Icon(Icons.local_offer_outlined),
                        title: Text('Special Discount').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.SpecialOffer;
                            _appBarTitle = 'Special Discount'.tr();
                            _currentWidget = SpecialOfferScreen();
                          });
                        },
                      ),
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.Offers,
                      leading: Icon(Icons.local_offer_outlined),
                      title: Text('Offers').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.Offers;
                          _appBarTitle = 'Offers'.tr();
                          _currentWidget = OffersScreen();
                        });
                      },
                    ),
                  ),
                  Visibility(
                    visible: (selectedModel != null && selectedModel!.serviceTypeFlag != "ecommerce-service") ? true : false,
                    child: ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.WorkingHours,
                        leading: Icon(Icons.access_time_sharp),
                        title: Text('Working Hours').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.WorkingHours;
                            _appBarTitle = 'Working Hours'.tr();
                            _currentWidget = WorkingHoursScreen();
                          });
                        },
                      ),
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.Profile,
                      leading: Icon(CupertinoIcons.person),
                      title: Text('Profile').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.Profile;
                          _appBarTitle = 'Profile'.tr();
                          _currentWidget = ProfileScreen(
                            user: MyAppState.currentUser!,
                          );
                        });
                      },
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.Wallet,
                      leading: Icon(Icons.account_balance_wallet_sharp),
                      title: Text('Wallet').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.Wallet;
                          _appBarTitle = 'Wallet'.tr();
                          _currentWidget = WalletScreen();
                        });
                      },
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.BankInfo,
                      leading: Icon(Icons.account_balance),
                      title: Text('Bank Details').tr(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _drawerSelection = DrawerSelection.BankInfo;
                          _appBarTitle = 'Bank Info'.tr();
                          _currentWidget = BankDetailsScreen();
                        });
                      },
                    ),
                  ),
                  Visibility(
                    visible: isLanguageShown,
                    child: ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.chooseLanguage,
                        leading: Icon(
                          Icons.language,
                          color: _drawerSelection == DrawerSelection.chooseLanguage
                              ? Color(COLOR_PRIMARY)
                              : isDarkMode(context)
                                  ? Colors.grey.shade200
                                  : Colors.grey.shade600,
                        ),
                        title: const Text('Language').tr(),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.chooseLanguage;
                            _appBarTitle = 'Language'.tr();
                            _currentWidget = LanguageChooseScreen(
                              isContainer: true,
                            );
                          });
                        },
                      ),
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.termsCondition,
                      leading: const Icon(Icons.policy),
                      title: const Text('Terms and Condition').tr(),
                      onTap: () async {
                        push(context, const TermsAndCondition());
                      },
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.privacyPolicy,
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy policy').tr(),
                      onTap: () async {
                        push(context, const PrivacyPolicyScreen());
                      },
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.inbox,
                      leading: Icon(CupertinoIcons.chat_bubble_2_fill),
                      title: Text('Inbox').tr(),
                      onTap: () {
                        if (MyAppState.currentUser == null) {
                          Navigator.pop(context);
                          push(context, AuthScreen());
                        } else {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.inbox;
                            _appBarTitle = 'My Inbox'.tr();
                            _currentWidget = InboxScreen();
                          });
                        }
                      },
                    ),
                  ),
                  ListTileTheme(
                    style: ListTileStyle.drawer,
                    selectedColor: Color(COLOR_PRIMARY),
                    child: ListTile(
                      selected: _drawerSelection == DrawerSelection.Logout,
                      leading: Icon(Icons.logout),
                      title: Text('Log out').tr(),
                      onTap: () async {
                        audioPlayer.stop();
                        Navigator.pop(context);
                        //user.active = false;
                        MyAppState.currentUser!.lastOnlineTimestamp = Timestamp.now();
                        await FireStoreUtils.firestore.collection(USERS).doc(MyAppState.currentUser!.userID).update({"fcmToken": ""});
                        if (MyAppState.currentUser!.vendorID.isNotEmpty) {
                          await FireStoreUtils.firestore.collection(VENDORS).doc(MyAppState.currentUser!.vendorID).update({"fcmToken": ""});
                        }
                        // await FireStoreUtils.updateCurrentUser(user);
                        await auth.FirebaseAuth.instance.signOut();
                        await FacebookAuth.instance.logOut();
                        MyAppState.currentUser = null;
                        pushAndRemoveUntil(context, AuthScreen(), false);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Version".tr() + " : $appVersion"),
            )
          ],
        ),
      )),
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: _drawerSelection == DrawerSelection.Wallet
              ? Colors.white
              : isDarkMode(context)
                  ? Colors.white
                  : Color(DARK_COLOR),
        ),
        centerTitle: _drawerSelection == DrawerSelection.Wallet ? true : false,
        backgroundColor: _drawerSelection == DrawerSelection.Wallet
            ? Colors.transparent
            : isDarkMode(context)
                ? Color(DARK_COLOR)
                : Colors.white,
        actions: [
          // if (_currentWidget is ManageProductsScreen)
          // IconButton(
          //   icon: Icon(
          //     CupertinoIcons.add_circled,
          //     color: Color(COLOR_PRIMARY),
          //   ),
          //   onPressed: () => push(
          //     context,
          //     AddOrUpdateProductScreen(product: null),
          //   ),
          // ),
        ],
        title: Text(
          _appBarTitle,
          style: TextStyle(
            fontSize: 20,
            color: _drawerSelection == DrawerSelection.Wallet
                ? Colors.white
                : isDarkMode(context)
                    ? Colors.white
                    : Color(DARK_COLOR),
          ),
        ),
      ),
      body: WillPopScope(
          onWillPop: () async {
            final timegap = DateTime.now().difference(pre_backpress);
            final cantExit = timegap >= Duration(seconds: 2);
            pre_backpress = DateTime.now();
            if (cantExit) {
              //show snackbar
              final snack = SnackBar(
                content: Text(
                  'Press Back button again to Exit'.tr(),
                  style: TextStyle(color: Colors.white),
                ),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.black,
              );
              ScaffoldMessenger.of(context).showSnackBar(snack);
              return false; // false will do nothing when back press
            } else {
              return true; // true will exit the app
            }
          },
          child: _currentWidget),
    );
  }

  Future<void> getLanguages() async {
    await FireStoreUtils.firestore.collection(Setting).doc("languages").get().then((value) {
      List list = value.data()!["list"];
      isLanguageShown = (list.length > 0);
      setState(() {});
    });
  }
}
