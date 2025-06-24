import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_trade/BLOC/DataBloc.dart';
import 'package:my_trade/BLOC/DataEvent.dart';
import 'package:my_trade/BLOC/DataState.dart';
import 'package:my_trade/BuyProduct.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Utils/AppColors.dart';

import 'Utils/Constants.dart';

class ShowProducts extends StatefulWidget {
  String distributorName;
  String userId;

  ShowProducts(this.distributorName, this.userId);

  @override
  State<ShowProducts> createState() => _ShowProductsState();
}

class _ShowProductsState extends State<ShowProducts> {
  TextEditingController _searchController = TextEditingController();
  double _gResponsiveFontSize = 0;
  int numberOfSearchedStocksTypeAvailable = 0;
  List<dynamic> productNames = [];
  List<dynamic> searchedProducts = [];
  bool searchIsEmpty = false;



  @override
  void initState() {
    // TODO: implement initState
    print("init SHowProducts");
    super.initState();
    _initialize();
  }

  _initialize(){
    context.read<DataBloc>().add(FetchData("getMyProducts", widget.userId));
  }

  void searchProducts(){

  }
  @override
  Widget build(BuildContext context) {

    // get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_back_ios, color: AppColors.lightGray,)),
        title: Text(
          widget.distributorName,
          style: TextStyle(
              color: AppColors.lightGray, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.steelBlue,
      ),
      body: SafeArea(child: Column(children: [
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
                    // onChanged: searchProducts,
                    textCapitalization: TextCapitalization.words,
                    controller: _searchController,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search..",
                      hintStyle: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.black,
                          fontSize: _gResponsiveFontSize - 4),
                      prefixIcon: Icon(Icons.search),
                    ),
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: _gResponsiveFontSize - 2),
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
                          fontSize: _gResponsiveFontSize - 2),
                    ),
                  ),
                )
              ],
            )),
        SizedBox(
          height: 10,
        ),
        Expanded(
          child: BlocBuilder<DataBloc, DataState>(builder: (context, state){
            if(state.dataStatus == DataStatus.success){
              return showProducts(state.productDataMap);
            }else{
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
        )
      ],)),
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
                        builder: (context) => BuyProduct(
                            searchIsEmpty ? map[productNames[index]] : map[searchedProducts[index]],
                            searchIsEmpty ?  productNames[index] : searchedProducts[index], searchIsEmpty ? getImage(map[productNames[index]]) : getImage(map[searchedProducts[index]]), widget.userId
                        )));
              },
              child: Container(
                margin: EdgeInsets.all(8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyMedium.withOpacity(0.8), width: 2.5),
                    color: AppColors.steelBlue.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(10)),
                child: Expanded(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:   getImage(searchIsEmpty ? map[productNames[index]] : map[searchedProducts[index]]).isNotEmpty
                            ? Image.network(
                          searchIsEmpty ? getImage(map[productNames[index]]) : getImage(map[searchedProducts[index]]),
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
