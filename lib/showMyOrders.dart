import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/MyCart.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/Utils/Constants.dart';
import 'package:my_trade/Utils/CustomCacheManager.dart';
import 'package:my_trade/main.dart';

import 'UPI.dart';

class ShowMyOrders extends StatefulWidget {
  // if the user is a retailer then the id will be of distributor and vice versa.
  final String userId;
  final String firmName;

  ShowMyOrders(this.userId, this.firmName);

  @override
  State<ShowMyOrders> createState() {
    return _ShowMyOrdersState();
  }
}

List<Map<dynamic, dynamic>> variantDetails = [];
bool isLoading = true;
double _gResponsiveFontSize = 0.0;

class _ShowMyOrdersState extends State<ShowMyOrders> {
  bool variantsLoaded = false;
  String _orderStatus = "";
  String _finalOrderStatus = "";
  var productName = "";
  var productQuantity = 0;
  var productPrice = 0;
  var variantName = "";
  var orderStatus = "";
  Map<dynamic, dynamic> variantImagesMap = {};
  String _profileImageUrl = "";
  List<String> productNamesList = [];
  List<int> totalPriceList = [];
  Map<dynamic, dynamic> productImagesMap = {};
  int totalPrice = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      for (var tp in totalPriceList) {
        totalPrice += tp;
        print("BBBBBBBBBBBBBBBBBBBBBBBBBBBB ${totalPrice}");
      }
    });
    _initialize();
  }

  _initialize() async {
    variantDetails = await MyFirebase.getOrderVariants(widget.userId);

    for(var v in variantDetails){
      print("loooop ${v}");
      var productName = v['Product Name'];
      if(!productNamesList.contains(productName)){
        productNamesList.add(productName);
      }

      print("Looooop product name is ${productNamesList}");

    productImagesMap =  await  MyFirebase.getProductImages(productNamesList, widget.userId);
      print("productImagesMap ${productImagesMap}");

    }

    print("ShowMyOrders variantDetails ${variantDetails}");
    setState(() {
      variantsLoaded = true;
    });

    if (variantsLoaded == true) {
      // _orderStatus = await MyFirebase.checkIfOrderAccepted(widget.userId, productName, variantName);

      _finalOrderStatus = _orderStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    _gResponsiveFontSize = Constants.baseFontSize * (screenWidth / 375);

    return Scaffold(
      appBar: AppBar(
          title: Text(
            "Orders",
            style: TextStyle(
                color: AppColors.lightGray, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: AppColors.steelBlue,
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColors.lightGray,
              ))),
      body: SafeArea(
          child: !variantsLoaded
              ? Container(
                  child: Center(
                    child: Text("No Data"),
                  ),
                )
              : Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(
                        "${widget.firmName}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.charcoal),
                      ),
                      Expanded(
                        child: ListView.builder(
                            itemCount: variantDetails.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.greyMedium, width: 2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Builder(builder: (_) {
                                      final mapCopy = Map.of(variantDetails[index]);
                                      variantName = mapCopy['Variant Name'];
                                      mapCopy.remove('Variant Name');
                                      productName = mapCopy['Product Name'];
                                      productQuantity = mapCopy['Ordered Quantity'];
                                      productPrice = int.parse(mapCopy['productPrice']);
                                      totalPriceList.add(productPrice * productQuantity);
                                      mapCopy.remove('Product Name');
                                      orderStatus = mapCopy['Status'];
                                      mapCopy.remove('Status');

                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: productImagesMap[productName] != null && productImagesMap[productName].toString().isNotEmpty
                                                  ? CachedNetworkImage(
                                                imageUrl: productImagesMap[productName] ?? '',
                                                cacheManager: CustomCacheManager(),
                                                height: 80,
                                                width: 80,
                                                fit: BoxFit.fill,
                                              )
                                                  : Image.asset(
                                                'assets/images/no_image.png',
                                                height: 80,
                                                width: 80,
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "$productName",
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold, fontSize: 18),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      Text(
                                                        " (₹${productPrice * productQuantity})",
                                                        style: TextStyle(
                                                            color: AppColors.charcoal,
                                                            fontWeight: FontWeight.bold),
                                                      )
                                                    ],
                                                  ),
                                                  SizedBox(height: 10),
                                                  ...mapCopy.entries.map(
                                                        (entry) => Text(
                                                      "${entry.key}: ${entry.value}",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.charcoal,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),

                                  // Delete Icon
                                  if(!Constants.isDistributor)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: Icon(Icons.delete, color: AppColors.charcoal),
                                        onPressed: () {
                                          //  delete the product/variant
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext dialogContext) {
                                              return AlertDialog(
                                                title: Text("Delete Order"),
                                                content: Text(
                                                  "Are you sure you want to delete this order?",
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.charcoal),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(dialogContext);
                                                    },
                                                    child: Text("No", style: TextStyle(color: AppColors.electricGreen, fontWeight: FontWeight.bold),),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      await MyFirebase.deleteOrder(widget.userId, variantName, productName);
                                                      var tno = aboutUser.getInt(Constants.stringTotalNumberOfOrders);
                                                      aboutUser.setInt(Constants.stringTotalNumberOfOrders, tno ?? 0-1);

                                                      setState(() {
                                                        variantDetails.removeAt(index);
                                                        totalPriceList.clear();
                                                        totalPrice = 0;
                                                      });
                                                      Navigator.pop(dialogContext);
                                                    },
                                                    child: Text("Yes", style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold),),
                                                  )
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              );

                            }),
                      ),
                      InkWell(
                        onTap: () {
                          if(!Constants.isDistributor){
                            for (var tp in totalPriceList) {
                              totalPrice += tp;
                              print("BBBBBBBBBBBBBBBBBBBBBBBBBBBB ${totalPrice}");
                            }
                          }
                          showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return Container(
                                  height: screenHeight * .25,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      color: AppColors.lightGray,
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          topRight: Radius.circular(6))),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        height: 6,
                                      ),
                                      Text(
                                        "Total payable : ${totalPrice}",
                                        style: TextStyle(
                                            color: AppColors.charcoal,
                                            fontWeight: FontWeight.bold,
                                            fontSize: _gResponsiveFontSize),
                                      ),
                                      SizedBox(
                                        height: 6,
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                height: screenHeight * 0.05,
                                                padding: EdgeInsets.all(10),
                                                margin: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: AppColors.primary),
                                                child: Center(
                                                    child: Text(
                                                  "COD",
                                                  style: TextStyle(
                                                      color:
                                                          AppColors.lightGray,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                onTap: (){
                                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => UPI()));
                                                  Constants.launchPhonePe(totalPrice.toString(), context);
                                                },
                                                child: Container(
                                                  height: screenHeight * 0.05,
                                                  padding: EdgeInsets.all(10),
                                                  margin: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: AppColors.primary),
                                                  child: Center(
                                                      child: Text("UPI",
                                                          style: TextStyle(
                                                              color: AppColors
                                                                  .lightGray,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold))),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              });
                        },
                        child: !Constants.isDistributor ?  Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.steelBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                              child: Text(
                            "Checkout",
                            style: TextStyle(
                                color: AppColors.lightGray,
                                fontWeight: FontWeight.bold),
                          )),
                        ) : SizedBox.shrink()
                      )
                    ],
                  ),
                )),
    );
  }



}
