import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_trade/BLOC/DataBloc.dart';
import 'package:my_trade/BLOC/DataEvent.dart';
import 'package:my_trade/ShowMyProfile.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Auth/Login.dart';
import 'package:my_trade/ManageStock.dart';

import 'Utils/Constants.dart';

class Sidemenu extends StatefulWidget {
  const Sidemenu({super.key});

  @override
  State<Sidemenu> createState() => _SidemenuState();
}

class _SidemenuState extends State<Sidemenu> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    return Drawer(
      child: SafeArea(
          child: Column(

            children: [
              CircleAvatar(
                radius: screenHeight * 0.145,
                backgroundColor: AppColors.skyBlue.withOpacity(0.5),
              ),
              SizedBox(height: 10,),
              if(Constants.isDistributor) SideButton("My Stock", Icon(Icons.add_box)),
              SideButton("My Followers", Icon(Icons.unfold_less_outlined)),
              SideButton("My Profile", Icon(Icons.manage_accounts_rounded)),
              SideButton("Logout", Icon(Icons.power_settings_new))
            ],
          )),
    );
  }

  Widget SideButton(String text, Icon icon) {
    return Container(
      padding: EdgeInsets.all(12),
      child: TextButton(
          style: ButtonStyle(
              backgroundColor:
              text == "delete my account" ? WidgetStateProperty.all(Colors.red)
                  : WidgetStateProperty.all(
                  AppColors.steelBlue.withOpacity(0.95)),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)))),

          onPressed: () async {
            if (text == "My Stock") {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ManageStock()));
            } else if (text == "Logout") {
              showDialog(
                  context: context, builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: Text("Logout"),
                  content:Text("Are you sure you want to logout?",
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: AppColors.charcoal),),
                  actions: [
                    TextButton(onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                          builder: (context) => Login()), (
                          Route<dynamic> route) => false);
                    }, child: Text("Yes", style: TextStyle(color: AppColors.red,
                        fontWeight: FontWeight.bold),)),
                    TextButton(onPressed: () {
                      Navigator.pop(dialogContext);
                    }, child: Text("No", style: TextStyle(fontWeight: FontWeight
                        .bold, color: AppColors.electricGreen),))
                  ],
                );
              });
            }else if(text == "My Profile"){
              context.read<DataBloc>().add(FetchData("getMyProfileData", null));
              Navigator.push(context, MaterialPageRoute(builder: (context) => ShowMyProfile()));
            }
          },
          child: Row(
            children: [
              Icon(icon.icon, color: AppColors.lightGray,),
              SizedBox(width: 10,),
              Text(text, style: TextStyle(
                  color: AppColors.lightGray, fontWeight: FontWeight.bold),)
            ],
          )),
    );
  }
}


