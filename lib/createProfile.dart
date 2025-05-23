
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_trade/AppColors.dart';

class CreateProfile extends StatefulWidget {

  const CreateProfile({super.key});

  @override
  State<CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {
  bool selectedTraderType = false;
  bool  isRetailer = false;
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return
      selectedTraderType ?
      createTrader()
          : selectTraderType(screenHeight, screenWidth);


  }

  Widget selectTraderType(double screenHeight, double screenWidth){
    return Scaffold(
        appBar: AppBar(
          title: Text("Create Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Roboto'),),
          centerTitle: true,
          backgroundColor: AppColors.steelBlue,
        ),
        body: SafeArea(child: Center(
          child: Container(
            height: screenHeight*0.5,
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.charcoal,
                    width: 2
                )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: (){
                        setState(() {
                          selectedTraderType = true;
                          isRetailer = false;
                        });
                      },
                      child: Image.asset(
                        'assets/images/distributor.png',
                        width: screenWidth*0.3,
                      ),
                    ),
                    Text("Distributor")
                  ],
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: (){
                        setState(() {
                          selectedTraderType = true;
                          isRetailer = true;
                        });
                      },
                      child: Image.asset(
                        'assets/images/retailer.png',
                        width: screenWidth*0.3,
                      ),
                    ),
                    Text("Retailer")
                  ],
                )
              ],
            ),
          ),
        )
        )) ;
  }

  Widget createTrader(){
    return Scaffold(
      appBar: AppBar(title:Text(isRetailer ? "Retailer" : "Distributor"), centerTitle: true, backgroundColor: AppColors.steelBlue,),
      body: SafeArea(child:
      Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SingleChildScrollView(
          child: Column(

            children: [
              CircleAvatar(
                radius: 100,
                backgroundColor: AppColors.lightrGray,
              ),
              SizedBox(height: 20,),
              textField("Name Of The Shop"),
              SizedBox(height: 10,),
              textField("Name Of The Owner"),
              SizedBox(height: 10,),
              textField("GSTIN (Optional)")


            ],
          ),
        ),


      )
      ),
    );
  }

  Widget textField(String label){
    return TextField(
      decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.charcoal)
          ),

          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.darkTeal, width: 2)
          ),
          labelText: label,
          border: OutlineInputBorder(),
          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.charcoal)
      ),

    );
  }
}