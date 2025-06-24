import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/BLOC/DataBloc.dart';
import 'package:my_trade/BLOC/DataState.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Utils/CustomCacheManager.dart';
import 'package:my_trade/AddInventory.dart';
import 'package:my_trade/UpdateInventory.dart';

import 'BLOC/DataEvent.dart';
import 'Utils/Constants.dart';

class ManageStock extends StatefulWidget {
  const ManageStock({super.key});

  @override
  State<ManageStock> createState() => _ManageStockState();
}

class _ManageStockState extends State<ManageStock> {
  List<String> imageUrls = [];
  TextEditingController _searchController = TextEditingController();
  List<dynamic> productNames = [];
  List<dynamic> searchedProducts = [];
  bool searchIsEmpty = false;
  int numberOfSearchedStocksTypeAvailable = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<DataBloc>().add(FetchData(Constants.blocStringGetMyProducts, Constants.myUserId));
  }

  void searchProducts(String query){
    setState(() {
      searchedProducts = productNames.where((item) => item.toString().toLowerCase().contains(query.toLowerCase())).toList();
      searchedProducts.sort();
      numberOfSearchedStocksTypeAvailable = searchedProducts.length;

    });

  }

  @override
  Widget build(BuildContext context) {
    // get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        title: Text(
          "Manage Stock",

          style: TextStyle(
            color: AppColors.lightGray,
            fontWeight: FontWeight.bold
          ),
        ),
        leading: TextButton(onPressed: (){
          context.read<DataBloc>().add(FetchData(Constants.blocStringGetOrders, Constants.myUserId));
          Navigator.pop(context);
        }, child: Icon(Icons.arrow_back_ios,color: AppColors.lightGray,), ),
        centerTitle: true,
      ),
      body: SafeArea(
          child: Column(
        children: [
          Container(
              padding: EdgeInsets.all(0),
              margin: EdgeInsets.only(bottom: 10, top: 10, left: 15, right: 15),
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: AppColors.white,
                  border: Border.all(color: AppColors.greyMedium, width: 1.2)),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: TextField(
                      onChanged: searchProducts,
                      textCapitalization: TextCapitalization.words,
                      controller: _searchController,
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search..",
                        hintStyle: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.black,
                            fontSize: Constants.gResponsiveFontSize - 4),
                        prefixIcon: Icon(Icons.search),
                      ),
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: Constants.gResponsiveFontSize - 2),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 10, top: 10),
                      child: Text(
                        "$numberOfSearchedStocksTypeAvailable",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: Constants.gResponsiveFontSize - 2),
                      ),
                    ),
                  )
                ],
              )),
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: BlocBuilder<DataBloc, DataState>(builder: (context, state) {
              if (state.dataStatus == DataStatus.success && state.title == Constants.blocStringGetMyProducts) {

                print("manageStock productDataMap ${state.productDataMap}");


                return showProducts(state.productDataMap);
              } else {
                return Center(
                  child: Text("No Data"),
                );
              }
            }),
          ),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Addinventory()));
        },
        child: Icon(
          Icons.add,
          color: AppColors.charcoal,
        ),
        backgroundColor: AppColors.skyBlue.withOpacity(0.9),
      ),
    );
  }

  Widget showProducts(Map<dynamic, dynamic>? map) {
    searchIsEmpty = _searchController.text.isEmpty;
    bool DataIsNull = map == null;
    if(!DataIsNull){
      productNames = map.keys.toList();
      productNames.sort();
      numberOfSearchedStocksTypeAvailable = productNames.length;
      print("showProducts productNamesAre ${productNames}");
    }
    return DataIsNull
        ? Container(
            child: Center(
              child: Text("No Products"),
            ),
          )
        : Container(
            padding: EdgeInsets.all(15),
            child: ListView.builder(
                itemCount: searchIsEmpty ? productNames.length : searchedProducts.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      print(
                          "ManageStock inkwell ${map.values.toList()[index]}");
                      print("ManageStock inkwell ${map.keys.toList()[index]}");
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UpdateInventory(
                                 searchIsEmpty ? map[productNames[index]] : map[searchedProducts[index]],
                                  searchIsEmpty ?  productNames[index] : searchedProducts[index], null)));
                    },
                    child: Container(
                      margin: EdgeInsets.all(8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.greyMedium.withOpacity(0.8), width: 2.5),
                          color: AppColors.steelBlue.withOpacity(0.85),
                          gradient: LinearGradient(colors:
                          [AppColors.primary.withOpacity(0.8), AppColors.tertiary.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                            end: Alignment.centerRight
                          ),
                          borderRadius: BorderRadius.circular(10)),
                      child: Expanded(
                        child: Row(
                          children: [
                            // getImage(map[productNames[index]]) : getImage(map[searchedProducts[index]])
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),

                              child:   getImage(searchIsEmpty ? map[productNames[index]] : map[searchedProducts[index]]).isNotEmpty
                                  ? Image(image:
                                      searchIsEmpty ? CachedNetworkImageProvider(getImage(map[productNames[index]]), cacheManager: CustomCacheManager())
                                      : CachedNetworkImageProvider(getImage(map[searchedProducts[index]]), cacheManager: CustomCacheManager()),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/no_image.png',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            SizedBox(
                              width: 25,
                            ),
                            Text(
                              searchIsEmpty ? productNames[index] : searchedProducts[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.lightGray,
                                  fontSize: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
          );
  }

   String getImage(Map<dynamic, dynamic> productDataMap) {
    print("ManageStock getImage ${productDataMap}");
    String? profileImageUrl = "";
      profileImageUrl = productDataMap['imageUrl'];
      if(profileImageUrl != null){
        return profileImageUrl;
      }else{
        return profileImageUrl = "";
      }

  }
}
