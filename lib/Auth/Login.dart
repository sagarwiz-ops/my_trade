import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/Utils/Constants.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Home.dart';
import 'package:my_trade/CreateProfile.dart';
import 'package:my_trade/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_autofill/sms_autofill.dart';


// for otp screen
Timer? _timer;
var _secondsRemaining = 30.obs;
TextEditingController otpController = TextEditingController();
var phoneNumber;
var _code = "".obs;
var gVerificationId;
bool hasInternet = false;
var isDeviceConnected = false;
bool isAlertDialogSet = false;
var internetConnectionChecker = InternetConnectionChecker.createInstance();
String distributorsUserIdForManager = "";


final TextEditingController _mobileNumberController = TextEditingController();
double _gResponsiveFontSize = 0.0;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isPhoneAuthWidgetVisible = true;

  void _handleVisibility() {
    setState(() {
      isPhoneAuthWidgetVisible = !isPhoneAuthWidgetVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    SmsAutoFill().unregisterListener();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    _gResponsiveFontSize = Constants.baseFontSize * (screenWidth / 375);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        title: Text(
          "Sign In",
          style: TextStyle(
              fontSize: _gResponsiveFontSize,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto'),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            isPhoneAuthWidgetVisible
                ? PhoneAuth(toggleScreen: _handleVisibility)
                : OtpVerificationScreen(toggleScreen: _handleVisibility)
          ],
        ),
      ),
    );
  }
}

class PhoneAuth extends StatefulWidget {
  final Function toggleScreen;

  PhoneAuth({required this.toggleScreen});

  @override
  State<PhoneAuth> createState() => _PhoneAuthState();
}

class _PhoneAuthState extends State<PhoneAuth> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getConnectivity();
  }

  showAlertDialogForNoInternet() async {
    isAlertDialogSet = true;
    showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
              title: Text(
                "No Internet Connection",
                style: TextStyle(
                    fontSize: _gResponsiveFontSize - 4,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold),
              ),
              content: Text("Please Check Your Internet Connection",
                  style: TextStyle(
                      fontSize: _gResponsiveFontSize - 4,
                      fontFamily: 'Roboto')),
              actions: [
                TextButton(
                    onPressed: () async {
                      // dismiss the dialog box
                      Navigator.pop(context);
                      isAlertDialogSet = false;
                      isDeviceConnected =
                          await internetConnectionChecker.hasConnection;
                      //  id there is no internet connection and the dialog box is not showing
                      if (!isDeviceConnected && !isAlertDialogSet) {
                        showAlertDialogForNoInternet();
                      }
                    },
                    child: Text("OK"))
              ],
            ));
  }

  getConnectivity() async {
    isDeviceConnected = await internetConnectionChecker.hasConnection;
    if (!isDeviceConnected && !isAlertDialogSet) {
      showAlertDialogForNoInternet();
      hasInternet = false;
    } else {
      hasInternet = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sign In",
          style: TextStyle(
              color: AppColors.lightGray, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "My Trade",
                style: TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.bold,
                    fontSize: 24),
              ),
              SizedBox(
                height: 25,
              ),
              TextField(
                controller: _mobileNumberController,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    prefixText: "+91 ",
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.charcoal)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppColors.steelBlue.withOpacity(0.6),
                            width: 2)),
                    labelText: "Mobile Number",
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal)),
              ),
              InkWell(
                onTap: () async {
                  await getConnectivity();
                  if (!isDeviceConnected) {
                    getConnectivity();
                  } else {
                    if (_mobileNumberController.text.isNotEmpty &&
                        _mobileNumberController.text.length == 10) {
                      Constants.showAToast("OTP Sent", context);
                      widget.toggleScreen.call();
                      verifyPhoneNumber("+91 ${_mobileNumberController.text}");
                    } else {
                      if (_mobileNumberController.text.isEmpty) {
                        Constants.showAToast(
                            "PLease Enter Mobile Number", context);
                      } else {
                        Constants.showAToast("Mobile Number Invalid", context);
                      }
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.steelBlue.withOpacity(0.8)),
                  child: Center(
                      child: Text(
                    "Get OTP",
                    style: TextStyle(
                        color: AppColors.lightGray,
                        fontWeight: FontWeight.bold),
                  )),
                ),
              )
            ],
                    ),
                  ),
          )),
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  final Function toggleScreen;

  OtpVerificationScreen({required this.toggleScreen});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  // smsAutoFill works only when the signature id in the sent otp and the local device matches.
  // the app signature is unique to the app's packahe name and the sha 256 certificate.
  var phoneNumber;
  var _code = "".obs;
  String? _appSignautre;

  @override
  void initState() {
    super.initState();
    _requestPermissions();

    // this activates the sms retriever API
    _listenForCode();

    Future.delayed(Duration(seconds: 8), () {
      if (_secondsRemaining == 30) {
        startTimer();
      } else {
        resetTimer();
      }
    });
  }

  @override
  void codeUpdated() {
    // after the received otp is read.
    _code.value = code!;
    print("the code has been updated ${_code}");
  }

  void _listenForCode() async {
    await SmsAutoFill().unregisterListener();
    await SmsAutoFill().listenForCode();
    print("lsitening for code");
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    SmsAutoFill().unregisterListener();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      color: AppColors.lightGray,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "OTP Verification",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _gResponsiveFontSize + 2,
                    fontFamily: 'Roboto',
                    color: Colors.black),
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                "Please enter the verification \n code sent to your mobile number",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: _gResponsiveFontSize - 1,
                    fontFamily: 'Roboto',
                    color: AppColors.charcoal),
              ),
              SizedBox(
                height: 4,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    // todo
                    _mobileNumberController.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: _gResponsiveFontSize,
                        fontFamily: 'Roboto'),
                  ),
                  SizedBox(
                    width: 2,
                  ),
                  IconButton(
                      // edit phone number
                      onPressed: () {
                        widget.toggleScreen.call();
                      },
                      icon: Icon(
                        Icons.edit_outlined,
                        color: AppColors.steelBlue,
                        size: 20,
                      )),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Obx(() => PinFieldAutoFill(
                    controller: otpController,
                    currentCode: _code.value,
                    codeLength: 6,
                    decoration: BoxLooseDecoration(
                        strokeColorBuilder:
                            PinListenColorBuilder(Colors.black, Colors.black),
                        textStyle: (TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.black,
                            fontSize: _gResponsiveFontSize - 3,
                            fontWeight: FontWeight.bold)),
                        strokeWidth: 2.0,
                        radius: Radius.circular(4),
                        bgColorBuilder: PinListenColorBuilder(
                            AppColors.lightGray, AppColors.lightGray)),
                    onCodeChanged: (code) {
                      _code.value = code!;
                    },
                  )),
              SizedBox(
                height: 4,
              ),
              Row(children: [
                SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(14),
                    child: TextButton(
                      // submit button
                      onPressed: () async {
                        print("gvid is ${gVerificationId}");
                        print("otp is ${otpController.text}");
                        if (otpController.text.isNotEmpty &&
                            otpController.text.length == 6) {
                          showDialog(
                              barrierColor: AppColors.lightGray,
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext hc) {
                                return Constants.showSpinKit();
                              });
                          try {
                            var credentials = PhoneAuthProvider.credential(
                                verificationId: gVerificationId,
                                smsCode: otpController.text);
                            await FirebaseAuth.instance
                                .signInWithCredential(credentials)
                                .then((_) async {
                              print("sign in with otp is successful");
                              Constants.hasJustLoggedIn = true;
                              print(
                                  "Login after successfully signing in mobile number is  ${_mobileNumberController.text}");
                  
                              if (await MyFirebase.checkIfTheUserIsValidated(
                                  "+91${_mobileNumberController.text}")) {
                               distributorsUserIdForManager =  await MyFirebase.getUserIdOfMyDistributor();
                               if(distributorsUserIdForManager!= null && distributorsUserIdForManager.isNotEmpty){
                                 aboutUser.setString(Constants.sharedPrefStringDistributorsUserIdForManager, distributorsUserIdForManager);
                                 aboutUser.setBool("isManager", true);
                                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
                  
                               }else{
                                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
                               }
                              } else {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CreateProfile(
                                            _mobileNumberController.text)));
                              }
                            });
                  
                            // Navigator.pop(context);
                          } on FirebaseAuthException catch (fae) {
                            if (fae.code == 'invalid-verification-code') {
                              Constants.showAToast("Invalid otp", context);
                              print("error signing in wrong otp");
                            } else if (fae.code == 'session-expired') {
                              Navigator.pop(context);
                              Constants.showAToast("OTP Expired", context);
                            } else {
                              // store phoneNumber in sharedPref after the user is successfully authenticated
                            }
                          } catch (e) {
                            print("error while signing in ${e}");
                            Navigator.pop(context);
                            Constants.showAToast(
                                "An error occured please try again", context);
                          }
                        } else {
                          Constants.showAToast("Invalid otp", context);
                        }
                      },
                      style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              AppColors.steelBlue.withOpacity(0.8)),
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                      color: AppColors.lightGray, width: 2)))),
                      child: Text(
                        "Submit",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.black,
                            fontSize: _gResponsiveFontSize - 2,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ]),
              Row(children: [
                SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(14),
                    child: TextButton(
                        // resend code button
                        onPressed: () {
                          phoneNumber = "+91 ${_mobileNumberController.text}";
                          otpController.text = "";
                          //  check if 30 seconds have elapsed
                          if (_secondsRemaining == 0) {
                            resetTimer();
                            //   resend otp
                            // showDialog(
                            //     barrierColor: AppColors.lightGray,
                            //     context: context,
                            //     builder: (BuildContext vm) {
                            //       // return Constants.showSpinKit();
                            //     });
                            if (phoneNumber == "+91 1234567890") {
                              Navigator.pop(context);
                              Constants.showAToast(
                                  "otp resent, please enter the otp", context);
                            } else {
                              FirebaseAuth.instance.verifyPhoneNumber(
                                  phoneNumber: phoneNumber,
                                  verificationCompleted:
                                      (PhoneAuthCredential credential) {},
                                  verificationFailed: (Exception ex) {
                                    print(ex);
                                  },
                                  codeSent: (String verificationId,
                                      int? resendToken) {
                                    // assigning the value of verification id to gVerification id so that it can be used for verification later
                                    gVerificationId = verificationId;
                                    Navigator.pop(context);
                                  },
                                  codeAutoRetrievalTimeout:
                                      (String verificationId) {});
                            }
                            _listenForCode();
                  
                            print("otp resent");
                          } else if (_secondsRemaining > 0) {
                            //   if 30 secs haven't elapsed
                            Constants.showAToast(
                                "After $_secondsRemaining seconds", context);
                          }
                        },
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                AppColors.lightGray.withOpacity(0.5)),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                        color: Colors.black.withOpacity(0.5),
                                        width: 2)))),
                        child: Obx(() {
                          if (_secondsRemaining > 0) {
                            return Text(
                              "$_secondsRemaining seconds remaining",
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: _gResponsiveFontSize - 4,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            );
                          } else {
                            return Text(
                              "Resend OTP",
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: _gResponsiveFontSize - 3,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            );
                          }
                        })),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        // reduce by 1 sec
        _secondsRemaining--;
      } else {
        // if 30 seconds have elapsed then cancel the timer
        _timer?.cancel();
      }
    });
  }

  void resetTimer() {
    setState(() {
      _secondsRemaining = 30.obs;
      Future.delayed(Duration(seconds: 15), () {
        startTimer();
      });
    });
  }

  void _requestPermissions() async {
    var smsPermission = await Permission.sms.status;
    if (!smsPermission.isGranted) {
      await Permission.sms.request();
    }
  }
}

void verifyPhoneNumber(String phoneNumber) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  await auth.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    // e.g., '+15551234567'
    verificationCompleted: (PhoneAuthCredential credential) async {
      // Auto-retrieval (Android only)
      await auth.signInWithCredential(credential);
      print("Signed in automatically");
    },
    verificationFailed: (FirebaseAuthException e) {
      print("Verification failed: ${e.message}");
    },
    codeSent: (String verificationId, int? resendToken) {
      // Save verificationId and ask user to enter OTP
      print("Code sent to $phoneNumber");

      // Save `verificationId` for later
      gVerificationId = verificationId;
    },
    codeAutoRetrievalTimeout: (String verificationId) {
      // Called after timeout
    },
  );
}

Future<UserCredential?> signInWithGoogle() async {
  try {
    // Trigger the Google Sign-In flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // User cancelled the sign-in

    // Get the authentication details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential for Firebase
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in the user with Firebase
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    return userCredential;
  } catch (e) {
    print('Google sign-in error: $e');
    return null;
  }
}

void _requestPermissions() async {
  var smsPermission = await Permission.sms.status;
  if (!smsPermission.isGranted) {
    await Permission.sms.request();
  }
}
