import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Utils/AppColors.dart';

import 'Utils/Constants.dart';

class Assignmanager extends StatefulWidget {
  const Assignmanager({super.key});

  @override
  State<Assignmanager> createState() => _AssignManagerState();
}

double _gResponsiveFontSize = 0;

class _AssignManagerState extends State<Assignmanager> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  Map<dynamic, dynamic> managerMap = {};
  String? _currentManagersPhoneNumber = "";
  String? _nameOfTheCurrentManager = "";
  bool detailsLoaded = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initialize();
  }

  _initialize() async {
    managerMap = await MyFirebase.getMyManager();
    print("AssignManager managerMap ${managerMap}");
    setState(() {
      detailsLoaded = true;
      _nameOfTheCurrentManager = managerMap['name'];
      print("name of the current manager ${_nameOfTheCurrentManager}");
      _currentManagersPhoneNumber = managerMap['phoneNumber'];
    });
  }

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

    _gResponsiveFontSize = Constants.baseFontSize * (screenWidth / 375);

    return !detailsLoaded ? Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_back_ios, color: AppColors.lightGray,)),
        title: Text(
          "Manager",
          style: TextStyle(
              color: AppColors.lightGray, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.steelBlue,
      ),
      body: SafeArea(child: Center(
        child: CircularProgressIndicator(color: AppColors.lightGray,),)),
    ) : Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_back_ios, color: AppColors.lightGray,)),
        actions: [
          IconButton(onPressed: () {
            if(_nameOfTheCurrentManager == null){
              Constants.showAToast("No manager Assigned", context);
            }else{
              showDialog(context: context, builder: (BuildContext cc) {
                return AlertDialog(
                  title: Text("Are you sure you want to remove the Manager?"),
                  actions: [
                    TextButton(onPressed: () {
                      Navigator.pop(cc);
                      showDialog(context: context, builder: (BuildContext bc) {
                        return AlertDialog(
                          title: Text(
                              "Are you really sure you want to remove the manager?"),
                          actions: [
                            TextButton(onPressed: () {
                              Navigator.pop(bc);
                            }, child: Text("No", style: TextStyle(color: AppColors.electricGreen),)),
                            TextButton(onPressed: () {
                              Navigator.pop(bc);
                              MyFirebase.deleteManager(_currentManagersPhoneNumber ?? "");
                              _initialize();
                            }, child: Text("Yes", style: TextStyle(color: AppColors.red),))
                          ],
                        );
                      });
                    }, child: Text("Yes", style: TextStyle(color: AppColors.red),)),
                    TextButton(onPressed: (){Navigator.pop(cc);}, child: Text("No", style: TextStyle(color: AppColors.electricGreen),))
                  ],
                );
              });
            }
          }, icon: Icon(Icons.delete, color: AppColors.lightGray,))
        ],
        title: Text(
          "Manager",
          style: TextStyle(
              color: AppColors.lightGray, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.steelBlue,
      ),
      body: SafeArea(

          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 15,),

                Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.greyMedium, width: 2)),
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Text("Name", style: TextStyle(color: AppColors.charcoal,
                          fontWeight: FontWeight.bold),),
                      SizedBox(
                        width: 10,
                      ),

                      Expanded(
                          child: TextField(
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.text,
                            controller: _nameController,
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                                border: InputBorder.none),
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: _gResponsiveFontSize - 2),
                          )),
                    ],
                  ),
                ),
                SizedBox(height: 10,),

                Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.greyMedium, width: 2)),
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(Icons.phone),
                      SizedBox(
                        width: 10,
                      ),

                      Expanded(
                          child: TextField(
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.number,
                            controller: _phoneNumberController,
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                                border: InputBorder.none),
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: _gResponsiveFontSize - 2),
                          )),
                    ],
                  ),
                ),
                SizedBox(height: 15,),
                InkWell(
                  onTap: () {
                    if (_phoneNumberController.text.isNotEmpty &&
                        _nameController.text.isNotEmpty &&
                        _phoneNumberController.text.length == 10) {
                      showDialog(context: context, builder: (BuildContext cc) {
                        return Constants.showSpinKit();
                      });
                      //   save manager
                      MyFirebase.saveMyManager(
                          "+91${_phoneNumberController.text}", _nameController.text,
                          _currentManagersPhoneNumber ?? "");
                      _initialize();
                      Navigator.pop(context);
                    } else if (_phoneNumberController.text.isEmpty) {
                      Constants.showAToast(
                          "Please Enter Phone Number", context);
                    } else if (_nameController.text.isEmpty) {
                      Constants.showAToast("Please Enter name", context);
                    } else if (_phoneNumberController.text.length != 10) {
                      Constants.showAToast("Phone Number Invalid", context);
                    }
                  },
                  child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      padding: EdgeInsets.all(6),
                      alignment: Alignment.center,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.steelBlue),
                      child: Text(
                        "Assign Manager",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            color: AppColors.white,
                            fontSize: _gResponsiveFontSize,
                            fontWeight: FontWeight.bold),
                      )),
                ),
                SizedBox(height: 20,),
                Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.all(10),
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.greyMedium.withOpacity(0.6),
                          width: 2.5)
                  ),
                  child: Column(
                    children: [
                      Text("Current Manager:", style: TextStyle(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),),
                      SizedBox(height: 15,),
                      Text(_nameOfTheCurrentManager ?? "", style: TextStyle(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.bold,
                          fontSize: 22),),
                      SizedBox(height: 10,),

                      Container(
                        height: 42,
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        padding: EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.steelBlue
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _currentManagersPhoneNumber ?? "", style: TextStyle(
                                color: AppColors.lightGray,
                                fontWeight: FontWeight.bold),),
                            IconButton(onPressed: () {
                              Constants.makePhoneCall(
                                  _currentManagersPhoneNumber ?? "");
                            }, icon: Icon(
                              Icons.call, color: AppColors.charcoal,))
                          ],
                        ),
                      )

                    ],
                  ),
                )
              ],
            ),
          )),
    );
  }
}
