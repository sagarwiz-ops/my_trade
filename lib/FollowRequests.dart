

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_trade/Utils/AppColors.dart';

class Followrequests extends StatefulWidget {
  const Followrequests({super.key});

  @override
  State<Followrequests> createState() => _FollowrequestsState();
}

class _FollowrequestsState extends State<Followrequests> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Follow Requests",),centerTitle: true, backgroundColor: AppColors.steelBlue,),
      body: SafeArea(child: Container(

    )),
    );
  }
}
