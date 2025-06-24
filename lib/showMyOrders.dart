import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/Utils/Constants.dart';

class ShowMyOrders extends StatefulWidget {
  // if the user is a retailer then the id will be of distributor and vice versa.
  final String userId;

  ShowMyOrders(this.userId);

  @override
  State<ShowMyOrders> createState() {
    return _ShowMyOrdersState();
  }
}

List<Map<dynamic, dynamic>> variantDetails = [];
bool isLoading = true;

class _ShowMyOrdersState extends State<ShowMyOrders> {
  bool variantsLoaded  =false;
  String _orderStatus = "";
  String _finalOrderStatus = "";
  var productName = "";
  var variantName = "";
  var orderStatus = "";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initialize();
  }

  _initialize() async {
    variantDetails = await MyFirebase.getOrderVariants(widget.userId);
    MyFirebase.getVariantImage("Plywood", widget.userId);
    print("ShowMyOrders variantDetails ${variantDetails}");
    setState(() {
      variantsLoaded = true;
    });

    if(variantsLoaded == true){
      // _orderStatus = await MyFirebase.checkIfOrderAccepted(widget.userId, productName, variantName);

        _finalOrderStatus = _orderStatus;

    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: !variantsLoaded ? Container(
            child: Center(child: Text("No Data"),),
          )
              
              :Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                  itemCount: variantDetails.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.greyMedium, width: 2),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            child: Image.asset(
                              'assets/images/no_image.png',
                              height: 80,
                              width: 80,
                            ),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Column(
                            children: [
                              Builder(builder: (_)    {
                                final mapCopy = Map.of(variantDetails[index]);
                                variantName = mapCopy['Variant Name'];
                                mapCopy.remove('Variant Name');
                                 productName = mapCopy['Product Name'];
                                mapCopy.remove('Product Name');


                                print(
                                    "map.copy product name is ${productName}");
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      "$productName",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    ...mapCopy.entries.map((entry) => Text(
                                          "${entry.key}: ${entry.value}",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.charcoal),
                                        )),
                                    Constants.isDistributor ?
                                    Row(
                                      children: [
                                        TextButton(
                                            onPressed: () {
                                              MyFirebase
                                                  .updateOrderStatus(
                                                      widget.userId,
                                                      variantDetails[index]
                                                          ['Product Name'],
                                                      variantDetails[index]
                                                          ['Variant Name'], "accepted");

                                              setState(() {
                                                Constants.showAToast(
                                                    "Order Accepted", context);
                                                variantDetails.removeAt(index);
                                              });
                                            },
                                            child: Text("Accept", style: TextStyle(color: AppColors.electricGreen.withOpacity(0.8)),)),
                                        SizedBox(
                                          width: 2,
                                        ),
                                        TextButton(
                                            onPressed: () async {
                                              await MyFirebase
                                                  .updateProductQuantity(
                                                      variantDetails[index]
                                                          ['Product Name'],
                                                      variantDetails[index]
                                                          ['Variant Name'],
                                                      variantDetails[index]
                                                          ['Ordered Quantity'].toString());

                                              await MyFirebase
                                                  .updateOrderStatus(
                                                      widget.userId,
                                                      variantDetails[index]
                                                          ['Product Name'],
                                                      variantDetails[index]
                                                          ['Variant Name'], "declined");

                                              setState(() {
                                                variantDetails.removeAt(index);
                                                Constants.showAToast(
                                                    "Order Declined", context);
                                              });
                                            },
                                            child: Text("Decline", style: TextStyle(color: AppColors.red),))
                                      ],
                                    )
                                        :Row(
                                      children: [
                                        Text("Status:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.charcoal),),
                                        SizedBox(width: 5,),
                                        Text("$_finalOrderStatus",style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.charcoal),)
                                      ],
                                    )
                                  ],
                                );
                              }),
                            ],
                          )
                        ],
                      ),
                    );
                  }),
            ),
          ],
        ),
      )),
    );
  }

  checkOrderAcceptance() async{
    _orderStatus =   await  MyFirebase.checkIfOrderAccepted(widget.userId, productName, variantName);
    setState(() {
      _finalOrderStatus = _orderStatus;
    });
  }


}
