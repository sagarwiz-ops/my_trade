

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/UpdateInventory.dart';
import 'package:my_trade/Utils/CustomCacheManager.dart';
import 'package:my_trade/main.dart';
import 'package:my_trade/showMyOrders.dart';

import 'Firebase/MyFirebase.dart';
import 'Utils/Constants.dart';

List<String?> selectedValues = [];
String? _profileImageUrl;
String previousSelectedValue = " ";
List<List<String>> tempList = [];
List<dynamic> tempHintList = [];
TextEditingController _productQuantityController = TextEditingController();

class BuyProduct extends StatefulWidget {
  final Map<dynamic, dynamic> dropDownLists;
  final String productName;
  final String? imageUrl;
  final String distributorUserId;

  BuyProduct(this.dropDownLists, this.productName, this.imageUrl,
      this.distributorUserId);

  @override
  State<BuyProduct> createState() => _BuyProductState();
}

class _BuyProductState extends State<BuyProduct> {
  Map<dynamic, dynamic> variantsMap = {};
  Map currentSelectedFeatures = {};
  var matchedVariantKey = "";
  String productQuantity = "00";
  String productPrice = "00";
  double _gResponsiveFontSize = 0;
  String? featureWithHyphen = null;
  bool shouldNotUseDropdown = false;
  List<Map<String, String>> addedProducts = [];
  Map<dynamic, dynamic> addedProduct = {};
  int numberOfProductsAdded = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initialize();
  }

  void _initialize() {
    numberOfProductsAdded = aboutUser.getInt(Constants.stringTotalNumberOfOrders) ?? 0;
    getProductVariants();
    widget.dropDownLists.forEach((key, value) {
      if (value is String) {
        _profileImageUrl = value;
        print("updateInventory profileImageUrlIs ${_profileImageUrl}");
      }
    });
    widget.dropDownLists.removeWhere((key, value) => value is String);

    selectedValues = List.generate(widget.dropDownLists.length, (_) => "-");
    print("the selected values are ${selectedValues}");

    tempHintList = widget.dropDownLists.keys.toList();
    print("UpdateInvnetory temp hint list is ${tempHintList}");

    // Suppose widget.dropDownLists is Map<String, dynamic>
    tempList = widget.dropDownLists.values
        .map((value) => List<String>.from(value))
        .toList();

    //   add - in every list
    for (int i = 0; i < widget.dropDownLists.values.toList().length; i++,) {
      tempList[i].add("-");
      print("temp list is ${tempList[i]}");
      print("list one is ${tempList[i]}");
    }

    assignDefaultValues(tempHintList);
  }

  getProductVariants() async {
    variantsMap = await MyFirebase.getProductVariants(
        widget.productName, widget.distributorUserId);
    print("UpdateInvnetroy get product variants fetching products successful");
    print(
        "UpdateInventory the products variants are variants map $variantsMap");
  }

  @override
  Widget build(BuildContext context) {
    // get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    _gResponsiveFontSize = Constants.baseFontSize * (screenWidth / 375);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        title: Text(
          widget.productName,
          style: TextStyle(
              color: AppColors.lightGray, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppColors.lightGray,
            )),
      ),
      body: SafeArea(
          child: Container(
        margin: EdgeInsets.all(10),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                widget.imageUrl != null
                    ? widget.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image(
                              image: CachedNetworkImageProvider(
                                  widget.imageUrl!,
                                  cacheManager: CustomCacheManager()),
                              fit: BoxFit.cover,
                              height: 100,
                              width: 100,
                            ))
                        : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/no_image.png',
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/no_image.png',
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Product Price: ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoal),
                        ),
                        Text(productPrice,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoal))
                      ],
                    ),
                    Row(
                      children: [
                        Text("Available Quantity:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoal)),
                        Text(productQuantity,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoal))
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  width: 50,
                ),
                // Stack(
                //   children: [
                //     IconButton(
                //         onPressed: () {},
                //         icon: Icon(
                //           Icons.shopping_cart,
                //           color: AppColors.charcoal,
                //           size: 40,
                //         )),
                //     Positioned(
                //         right: 4,
                //         top: 4,
                //         child: Text("$numberOfProductsAdded")),
                //   ],
                // )
              ],
            ),
            SizedBox(
              height: 6,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                width: screenWidth * 0.5,
                child: TextField(
                  controller: _productQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                          // check icon for buying a product
                          onPressed: () async {
                            addedProduct.addAll({
                              matchedVariantKey: _productQuantityController.text
                            });

                            if (!_productQuantityController.text
                                    .contains(',') &&
                                !_productQuantityController.text
                                    .contains('.') &&
                                _productQuantityController.text.isNotEmpty) {
                              if (await MyFirebase
                                  .checkAvailableQuantityAndSetOrderAccordingly(
                                      widget.productName,
                                      matchedVariantKey,
                                      widget.distributorUserId,
                                      context,
                                      int.parse(
                                          _productQuantityController.text))) {
                                await MyFirebase.setMyOrder(
                                    widget.distributorUserId,
                                    addedProduct,
                                    widget.productName);
                                var tno = aboutUser.getInt(Constants.stringTotalNumberOfOrders);
                                aboutUser.setInt(Constants.stringTotalNumberOfOrders, tno ?? 0+1);
                                Constants.showAToast("Order Placed", context);
                                setState(() {
                                  numberOfProductsAdded++;
                                  addedProduct.clear();
                                });
                                // addedProduct.addAll({
                                //   matchedVariantKey:
                                //       _productQuantityController.text
                                // });
                                var aac = int.parse(productQuantity);
                                setState(() {
                                  productQuantity = (aac -= int.parse(
                                          _productQuantityController.text))
                                      .toString();
                                });
                              }
                            }
                          },
                          icon: Icon(
                            Icons.done_outline,
                            color: AppColors.charcoal,
                          )),
                      label: Text(
                        "Enter Product Quantity",
                        style: TextStyle(color: AppColors.charcoal),
                      ),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: AppColors.charcoal, width: 2)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.charcoal))),
                ),
              ),
              Stack(
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ShowMyOrders(widget.distributorUserId, "")));
                      },
                      icon: Icon(
                        Icons.shopping_cart,
                        color: AppColors.charcoal,
                        size: 40,
                      )),
                  Positioned(
                      right: 4,
                      top: 4,
                      child: Text("$numberOfProductsAdded")),
                ],
              )

            ]),
            SizedBox(
              height: 10,
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: tempList.length,
                  itemBuilder: (context, index) {
                    return DropDownMenu(
                        tempHintList[index], tempList[index], index, null);
                  }),
            )
          ],
        ),
      )),
    );
  }

  Widget DropDownMenu(
      String hint, List list, int index, String? featureWithHyphen) {
    if (featureWithHyphen != null) {
      shouldNotUseDropdown = hint == featureWithHyphen;
    }
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: [
            AppColors.primary.withOpacity(0.6),
            AppColors.steelBlue.withOpacity(0.8),
          ], begin: Alignment.topRight, end: Alignment.bottomLeft)),
      child: DropdownButtonFormField(
        icon: Icon(
          Icons.arrow_drop_down,
          color: AppColors.white,
        ),
        // for selected text
        style: TextStyle(fontFamily: 'Roboto', color: AppColors.white),
        dropdownColor: AppColors.steelBlue.withOpacity(0.8),
        // default value
        value: selectedValues[index] ?? "-",
        onChanged: (value) {
          if (shouldNotUseDropdown) {
            Constants.showAToast("Feature Unavailable", context);
            return;
          } else {
            previousSelectedValue = selectedValues[index] ?? " ";
            selectedValues[index] = value;
            print(
                "UpdateInventory current selected value in this index is ${previousSelectedValue}");
            print("UpdateInventory selected valus is ${value}");

            assignCurrentValues(hint, selectedValues[index]!, index);
          }
          // print("the length of selected value is ${selectedValues.length}");
        },
        decoration: InputDecoration(
            contentPadding: EdgeInsets.only(left: 6, bottom: 18),
            labelText: hint,
            border: InputBorder.none,
            labelStyle: TextStyle(
                fontFamily: 'Roboto',
                color: AppColors.white.withOpacity(
                  0.9,
                ),
                fontSize: _gResponsiveFontSize - 2,
                fontWeight: FontWeight.bold)),
        onTap: () {},
        items: list.map<DropdownMenuItem<dynamic>>((dynamic value) {
          return DropdownMenuItem<dynamic>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: _gResponsiveFontSize - 1),
            ),
          );
        }).toList(),
      ),
    );
  }

  assignDefaultValues(List<dynamic> hintList) {
    print("UpdateInvnetory ${selectedValues}");
    print("the hint is $hintList");

    for (String hint in hintList) {
      currentSelectedFeatures.addAll({hint: "-"});
    }
    print(
        "UpdateInvnetory assignDefaultValues are  ${currentSelectedFeatures} ");

    print(
        "UpdateInvnetory assign default values currentSelectedFeatures the map is ${currentSelectedFeatures}");
  }

  assignCurrentValues(String hint, String selectedValue, int index) async {
    print("assignCurrentValues ${selectedValue}");
    print("the hint is $hint");

    currentSelectedFeatures.addAll({hint: selectedValue});

    await getProductVariants();
    fetchTheVariant();
    print(
        "UpdateInvnetory currentSelectedFeatures the map is ${currentSelectedFeatures}");
  }

  void fetchTheVariant() {
    matchedVariantKey = "";
    print(
        "updateInventory selected values are at fetch the variant $selectedValues");

    print(
        "UpdateInventory fetchTheVariant previous selected value is ${previousSelectedValue}");
    // bool allSelected = selectedValues
    //     .every((value) => value != "-" && value != previousSelectedValue);

    Map<dynamic, dynamic> foundVariant = {};

    for (var entry in variantsMap.entries) {
      String key = "";
      String selectedValue = "";
      String variantValue = "";

      final variantValues = entry.value;
      print("updateInventory fetchTheVariant  variant values ${variantValues}");

      bool isMatched = currentSelectedFeatures.entries.every((featureEntry) {
        if (featureEntry.key == "productQuantity") return true;
        if (featureEntry.key == "productPrice") return true;
        key = featureEntry.key;
        selectedValue = featureEntry.value;
        variantValue = variantValues[key];

        print("key: $key, selected: $selectedValue, variant: $variantValue");

        if (selectedValue != "-") {
          return variantValue == selectedValue;
        } else {
          return false;
        }
      });

      if (isMatched) {
        print(
            "isMatched key: $key, selected: $selectedValue, variant: $variantValue");
        matchedVariantKey = entry.key;
        print("UpdateInventory isMatched ${matchedVariantKey}");
        foundVariant = variantValues;

        print("the found variant is ${foundVariant}");
        setState(() {
          foundVariant.forEach((key, value) {
            if (value == "-") {
              featureWithHyphen = key;
              print("is Matched h is $featureWithHyphen");
            }
          });

          final aq = foundVariant['productQuantity'] ?? "";
          final npp = foundVariant['productPrice'] ?? "";

          productPrice = npp;
          productQuantity = aq.toString();
        });
        break;
      } else {
        matchedVariantKey = "";
        setState(() {
          productPrice = "00";
          productQuantity = "00";
        });
      }
    }
  }

  addMyProduct(String variantKey, String quantity) {
    for (var product in addedProducts) {
      product.forEach((key, value) {
        if (key == variantKey) {
          var previousQuantity = value;
          var finalQuantity = int.parse(previousQuantity) + int.parse(quantity);
          product[key] = finalQuantity.toString();
          print("AddMyProduct, productNameIs ${product[key]}");
        } else {
          addedProducts
              .add({matchedVariantKey: _productQuantityController.text});
        }
      });
    }
  }
}
//
//
//
// showDialog(
// barrierDismissible: false,
// context: context,
// builder: (BuildContext dialogContext) {
// return AlertDialog(
// title: Text("Available Quantity:\n $productQuantity"),
// content: TextField(
// keyboardType: TextInputType.number,
// controller: _productQuantityController,
// decoration: InputDecoration(
// label: Text("Enter Product Quantity"),
// border: OutlineInputBorder(),
// focusedBorder: OutlineInputBorder(
// borderSide: BorderSide(
// color: AppColors.charcoal, width: 2)),
// enabledBorder: OutlineInputBorder(
// borderSide:
// BorderSide(color: AppColors.charcoal))),
// ),
// actions: [
// TextButton(
// onPressed: () {
// if (_productQuantityController
//     .text.isNotEmpty &&
// !_productQuantityController.text
//     .contains(',') &&
// !_productQuantityController.text
//     .contains('.')) {
//
// addMyProduct(matchedVariantKey, _productQuantityController.text);
//
// //   dismiss dialog
// Navigator.pop(dialogContext);
// setState(() {
// numberOfProductsAdded++;
// });
// } else if (_productQuantityController.text
//     .contains(',') ||
// _productQuantityController.text
//     .contains('.') ||
// _productQuantityController.text.isEmpty) {
// Constants.showAToast("Enter Correct Order Quantity", context);
// }
// },
// child: Text("Add Product")),
// TextButton(
// onPressed: () {
// // dismiss the dialog
// _productQuantityController.text = "";
// Navigator.pop(context);
// },
// child: Text("Cancel"))
// ],
// );
// });
