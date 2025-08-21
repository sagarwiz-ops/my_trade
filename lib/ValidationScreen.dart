


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:my_trade/Home.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/Utils/Constants.dart';

import 'Auth/Login.dart';
import 'Firebase/MyFirebase.dart';

class ValidationScreen extends StatefulWidget {
  const ValidationScreen({super.key});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  bool isLoggedIn = false;
  double _gResponsiveFontSize = 0;
  var _internetConnectionChecker = InternetConnectionChecker.createInstance();
  var _isDeviceConnected = false;
  bool _isAlertDialogSet = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_){
   _getConnectivity();
  });
  }
  validate() async {
    // if(await _getConnectivity()){
      if(await Constants.checkIfTheCurrentUserExists()){
        var phoneNumber  = FirebaseAuth.instance.currentUser!.phoneNumber;
        isLoggedIn = await MyFirebase.checkIfTheUserIsValidated(phoneNumber!);
        // Navigator.pop(context);
        isLoggedIn ? Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()))
            : Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
      }else{
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
      }
    // }else{
    //   _getConnectivity();
    // }
  }

  Future _getConnectivity() async {
    _isDeviceConnected = await _internetConnectionChecker.hasConnection;
    if (!_isDeviceConnected && !_isAlertDialogSet) {
      _showAlertDialogForNoInternet();

    } else {
      validate();
    }
  }

  _showAlertDialogForNoInternet() async {
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
                  _isAlertDialogSet = false;
                  _isDeviceConnected =
                  await internetConnectionChecker.hasConnection;
                  //  id there is no internet connection and the dialog box is not showing
                  if (!_isDeviceConnected && !_isAlertDialogSet) {
                    _showAlertDialogForNoInternet();
                  }else if(_isDeviceConnected && !_isAlertDialogSet){
                    _getConnectivity();
                  }
                },
                child: Text("OK"))
          ],
        ));
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    _gResponsiveFontSize = Constants.baseFontSize * (screenWidth / 375);
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: Center(
        child: Constants.showSpinKit()
      )
    );
  }
}
