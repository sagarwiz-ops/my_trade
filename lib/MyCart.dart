import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_trade/Utils/AppColors.dart';

import 'Utils/Constants.dart';

double _gResponsiveFontSize = 0.0;

class MyCart extends StatefulWidget {
  const MyCart({super.key});

  @override
  State<MyCart> createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    _gResponsiveFontSize = Constants.baseFontSize * (screenWidth / 375);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: TextStyle(
              color: AppColors.lightGray, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
          child: Container(
            height: screenHeight*0.5,
        child: Column(
          children: [],
        ),
      )),
    );
  }
}
