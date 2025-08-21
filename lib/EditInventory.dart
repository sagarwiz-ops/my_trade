import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:my_trade/Utils/Constants.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/ManageStock.dart';
import 'package:my_trade/UpdateInventory.dart';

import 'Utils/AppColors.dart';

class EditInventory extends StatefulWidget {
  final Map<dynamic, dynamic> featureList;
  final String productName;
  final String imageUrl;

  EditInventory(this.productName, this.featureList, this.imageUrl);

  @override
  State<EditInventory> createState() => _EditInventoryState();
}

late double _gResponsiveFontSize;

class _EditInventoryState extends State<EditInventory> {
  String? _imageUrl;
  int currentTextFieldPosition = 0;
  int featureNumber = 0;
  List<Widget> featureFields = [];
  List<List<String>> tempList = [];
  final Map<String, List<String>> featuresGroup = {};
  final Map<String, List<String>> newFeaturesGroup = {};
  final TextEditingController _featureController = TextEditingController();
  TextEditingController _subFeatureController = TextEditingController();
  bool _hasInternet = false;
  var _isDeviceConnected = false;
  bool _isAlertDialogSet = false;
  var _internetConnectionChecker = InternetConnectionChecker.createInstance();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    print("edit inventory class");

    print("EditInventory init the featuresList is ${widget.featureList}");

    checkInternetConnectionInitially();

    for (var key in widget.featureList.keys) {
      final value = widget.featureList[key];
      if (value is String) {
        _imageUrl = value;
        print("updateInventory profileImageUrlIs ${_imageUrl}");
        widget.featureList.removeWhere((key, value) => value is String);
      }

      print("the value is $value");
      featuresGroup.addAll({key: List<String>.from(value)});
      print("init ${featuresGroup}");
    }
    currentTextFieldPosition = (featuresGroup.keys.length * 2);
    initializeFields();
  }

  checkInternetConnectionInitially() async {
    _isDeviceConnected = await _internetConnectionChecker.hasConnection;
  }

  showAlertDialogForNoInternet() async {
    _isAlertDialogSet = true;
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
                          await _internetConnectionChecker.hasConnection;
                      //  id there is no internet connection and the dialog box is not showing
                      if (!_isDeviceConnected && !_isAlertDialogSet) {
                        showAlertDialogForNoInternet();
                      }
                    },
                    child: Text("OK"))
              ],
            ));
  }

  Future<void> _getConnectivity() async {
    _isDeviceConnected = await _internetConnectionChecker.hasConnection;
    if (!_isDeviceConnected && !_isAlertDialogSet) {
      showAlertDialogForNoInternet();
    }
  }

  void initializeFields() {
    for (var key in featuresGroup.keys) {
      print("EditInvnetory initializeFields ${featuresGroup.keys.length}");

      print(
          "EditInventory currentTextFieldPosition ${currentTextFieldPosition}");
      featureFields.add(container(key));
      featureFields.add(SizedBox(
        height: 15,
      ));
    }
  }

  void reInitializeFields() {
    for (var key in featuresGroup.keys) {
      featureFields.add(container(key));
      featureFields.add(SizedBox(
        height: 15,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    _gResponsiveFontSize = Constants.baseFontSize * (screenWidth / 375);
    print("both ${widget.featureList}");
    print("keys${widget.featureList.keys}");
    print("values ${widget.featureList.values}");

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          widget.productName,
          style: TextStyle(
              color: AppColors.lightGray, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // leading: TextButton(onPressed: (){
        //   Navigator.pop(context);
        // }, child: Icon(Icons.arrow_back_ios,color: AppColors.lightGray,), ),
        backgroundColor: AppColors.steelBlue,
        actions: [
          IconButton(
              // delete the product
              onPressed: () async {
                print("EditInventory product name is  ${widget.productName}");
                await _getConnectivity();
                if (!_isDeviceConnected) {
                  _getConnectivity();
                } else {
                  showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: Text("Delete Product"),
                          content: Text(
                            "Are you sure you want to delete the product?",
                            style: TextStyle(color: AppColors.charcoal),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () async {
                                  if (await MyFirebase.checkForExistingOrders(
                                      widget.productName)) {
                                    Constants.showAToast(
                                        "You have not fulfilled all the orders of this product",
                                        context);
                                  } else {
                                    await MyFirebase.deleteTheProduct(
                                        widget.productName, _imageUrl ?? "");
                                  }
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ManageStock()));
                                },
                                child: Text(
                                  "Yes",
                                  style: TextStyle(color: AppColors.charcoal),
                                )),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                child: Text(
                                  "No",
                                  style: TextStyle(color: AppColors.charcoal),
                                ))
                          ],
                        );
                      });
                }
              },
              icon: Icon(
                Icons.delete,
                color: AppColors.lightGray,
              )),
          IconButton(
              // check button for update/editing the inventory data of the product
              onPressed: () async {
                if (!mounted) return; // <-- Important check
                showDialog(context: context, barrierDismissible: false, builder: (BuildContext context){
                  return Constants.showSpinKit();
                });

                await Future.delayed(Duration.zero);

                await _getConnectivity();
                if (!_isDeviceConnected) {
                  // dismiss the dialog
                  Navigator.of(context, rootNavigator: true).pop();
                  _getConnectivity();
                } else {
                  if (featuresGroup.isEmpty) {
                    //   delete all the variants
                    await MyFirebase.deleteAllTheVariantsOfAProduct(
                        widget.productName);
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => ManageStock()));
                  } else {
                    // featuresGroup.addAll(newFeaturesGroup);
                    print(
                        "EditInventory onCheck afterAddingNewFeaturesList ${widget.featureList}");
                    print("EditInventory onCheck ${featuresGroup}");
                    await MyFirebase.updateProduct(
                        widget.productName, featuresGroup);
                    await MyFirebase.updateAllTheVariantsWithTheNewFeature(
                        widget.productName, List.from(newFeaturesGroup.keys));
                    print(
                        " EditInventory the feature controler is ${_featureController.text}");


                    // if the spin kit exists then pop it
                    // if(mounted){
                    //   Navigator.pop(_);
                    // }

                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UpdateInventory(featuresGroup,
                                widget.productName, widget.imageUrl ?? "")));
                  }
                }
              },

              icon: Icon(
                Icons.check,
                color: AppColors.lightGray,
              ))
        ],
      ),
      body: SafeArea(
          child: Container(
        padding: EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              // enter feature name dialog
                              return AlertDialog(
                                content: TextField(
                                  cursorColor: AppColors.charcoal,
                                  textCapitalization: TextCapitalization.words,
                                  controller: _featureController,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.steelBlue,
                                              width: 2)),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                        color: AppColors.charcoal,
                                      )),
                                      label: Text(
                                        "Feature Name",
                                        style: TextStyle(
                                            color: AppColors.charcoal),
                                      )),
                                ),
                                actions: [
                                  TextButton(
                                      // adding/creating the new feature
                                      onPressed: () {
                                        String name = _featureController.text.trim();
                                        if (name.isNotEmpty &&
                                            !featuresGroup.containsKey(name)) {
                                          // created a new map with the feature name as key. features group will contain both old and new list.
                                          featuresGroup[name] = [];
                                          // also add the newly created map into the new featuresGroup in order to add it to the final map later.
                                          // this will contain only newly created list
                                          newFeaturesGroup[name] = [];
                                          print(
                                              "EditInvnetory new feature has been added into the new features group ${newFeaturesGroup[name]}"
                                                  " ${newFeaturesGroup.keys}");

                                          setState(() {
                                            Navigator.pop(context);
                                            _featureController.text = "";
                                            featureNumber++;
                                            featureFields.insertAll(
                                                currentTextFieldPosition, [
                                              container("${name}"),
                                              SizedBox(height: 15)
                                            ]);
                                          });
                                        } else if(featuresGroup.containsKey(name)){
                                          Constants.showAToast("Feature Already Exists", context);

                                        }

                                        else {
                                          Constants.showAToast(
                                              "Please Enter Feature Name",
                                              context);
                                        }
                                      },
                                      child: Text(
                                        "Done",
                                        style: TextStyle(
                                            color: AppColors.charcoal),
                                      ))
                                ],
                              );
                            });
                      },
                      icon: Icon(Icons.add_box_outlined)),
                ],
              ),
              ...featureFields
            ],
          ),
        ),
      )),
    );
  }

  Widget container(String label) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: AppColors.greyMedium.withOpacity(0.4),
          border: Border.all(color: AppColors.charcoal, width: 2),
          borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () async {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                                builder: (context, setState) {
                              return AlertDialog(
                                title: Column(
                                  children: [
                                    Text(label),
                                    TextField(
                                      cursorColor: AppColors.charcoal,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      controller: _subFeatureController,
                                      decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: AppColors.steelBlue
                                                      .withOpacity(0.8),
                                                  width: 2)),
                                          enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: AppColors.charcoal)),
                                          label: Text(
                                            "Sub Feature",
                                            style: TextStyle(
                                                color: AppColors.charcoal),
                                          )),
                                    ),
                                  ],
                                ),
                                content: SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: ListView.builder(
                                      itemCount: featuresGroup[label]?.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                            child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Text(
                                              featuresGroup[label]?[index] ??
                                                  "No Category",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: AppColors.charcoal),
                                            ),
                                            IconButton(
                                                onPressed: () {
                                                  print(
                                                      "EditInventory removing ${featuresGroup[label]?[index]}");
                                                  setState(() {
                                                    MyFirebase
                                                        .deleteTheSubFeatureFromAllTheVariants(
                                                            featuresGroup[label]
                                                                    ?[index] ??
                                                                "",
                                                            widget.productName,
                                                            label);
                                                    if (newFeaturesGroup
                                                        .containsKey(label)) {
                                                      newFeaturesGroup[label]
                                                          ?.removeAt(index);
                                                    }
                                                    // if featuresGroup is null nothing will happen
                                                    featuresGroup[label]
                                                        ?.removeAt(index);
                                                  });
                                                },
                                                icon: Icon(Icons.delete))
                                          ],
                                        ));
                                      }),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        "Done",
                                        style: TextStyle(
                                            color: AppColors.charcoal,
                                            fontWeight: FontWeight.bold),
                                      )),
                                  TextButton(
                                      onPressed: () {
                                        if(newFeaturesGroup[label] == null){
                                          newFeaturesGroup[label] = [];
                                        }
                                        if (_subFeatureController
                                                .text.isNotEmpty &&
                                            !featuresGroup[label]!.contains(
                                                _subFeatureController.text.trim()) &&
                                            !newFeaturesGroup[label]!.contains(
                                                _subFeatureController.text.trim())) {
                                          print("${widget.featureList[label]}");

                                          featuresGroup[label]
                                              ?.add(_subFeatureController.text.trim());

                                          newFeaturesGroup[label]
                                              ?.add(_subFeatureController.text.trim());
                                          print(
                                              "after adding ${newFeaturesGroup}");

                                          setState(() {
                                            _subFeatureController.clear();
                                          });
                                        } else if (featuresGroup[label]!
                                                .contains(_subFeatureController
                                                    .text.trim()) ||
                                            newFeaturesGroup[label]!.contains(
                                                _subFeatureController.text)) {
                                          Constants.showAToast(
                                              "Sub Feature Already Exists",
                                              context);
                                        }else{

                                          Constants.showAToast(
                                              "Please enter the sub feature",
                                              context);
                                        }
                                      },
                                      child: Text(
                                        "Add",
                                        style: TextStyle(
                                            color: AppColors.charcoal,
                                            fontWeight: FontWeight.bold),
                                      ))
                                ],
                              );
                            });
                          });
                    },
                  icon: Icon(
                    Icons.add_box_outlined,
                    color: AppColors.charcoal,
                  )),
              SizedBox(
                width: 10,
              ),
              Text(
                label,
                style: TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          IconButton(
              onPressed: () async {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                              "Are you sure you want to delete this feautre?"),
                          actions: [
                            TextButton(
                                onPressed: () async {
                                  // delete the feature from all the existing variants
                                  await MyFirebase.removeFeatureFromAllVariants(
                                      widget.productName, label);
                                  Navigator.pop(context);
                                  print(
                                      "EditInventory onDelete before deleting ${featuresGroup}");
                                  setState(() {
                                    featuresGroup.remove(label);
                                    featureFields.clear();
                                    reInitializeFields();
                                  });
                                  print(
                                      "EditInventory onDelete after deleting ${featuresGroup}");
                                },
                                child: Text(
                                  "Yes",
                                  style: TextStyle(color: AppColors.charcoal),
                                )),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("No",
                                    style:
                                        TextStyle(color: AppColors.charcoal)))
                          ],
                        );
                      });
              },
              icon: Icon(
                Icons.delete,
                color: AppColors.charcoal,
              ))
        ],
      ),
    );
  }

  Widget textField(String label) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
          suffixIcon: IconButton(
              onPressed: () {
                showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(builder: (context, setState) {
                        return AlertDialog(
                          title: Column(
                            children: [
                              Text(label),
                              TextField(
                                cursorColor: AppColors.charcoal,
                                controller: _subFeatureController,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: AppColors.steelBlue, width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppColors.charcoal)),
                                    label: Text("Sub Feature")),
                              ),
                            ],
                          ),
                          content: SizedBox(
                            height: 200,
                            width: 200,
                            child: ListView.builder(
                                itemCount: featuresGroup[label]?.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    child: Text(
                                      featuresGroup[label]?[index] ??
                                          "No Category",
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "Done",
                                  style: TextStyle(color: AppColors.charcoal),
                                )),
                            TextButton(
                                onPressed: () {
                                  print("${widget.featureList[label]}");
                                  if (_subFeatureController.text.isNotEmpty) {
                                    featuresGroup[label]
                                        ?.add(_subFeatureController.text.trim());

                                    newFeaturesGroup[label]
                                        ?.add(_subFeatureController.text.trim());
                                    print("after adding ${newFeaturesGroup}");

                                    setState(() {
                                      _subFeatureController.clear();
                                    });
                                  } else {
                                    Constants.showAToast(
                                        "Please Enter The Sub Feature",
                                        context);
                                  }
                                },
                                child: Text(
                                  "Add",
                                  style: TextStyle(color: AppColors.charcoal),
                                ))
                          ],
                        );
                      });
                    });
              },
              icon: Icon(Icons.add_box_outlined)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.charcoal)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.steelBlue, width: 2)),
          labelText: label,
          border: OutlineInputBorder(),
          labelStyle: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.charcoal)),
    );
  }
}
