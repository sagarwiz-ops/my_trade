import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:my_trade/BLOC/DataBloc.dart';
import 'package:my_trade/EditInventory.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Utils/CustomCacheManager.dart';
import 'package:my_trade/AddInventory.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Utils/AppColors.dart';
import 'BLOC/DataEvent.dart';
import 'Utils/Constants.dart';

class UpdateInventory extends StatefulWidget {
  final Map<dynamic, dynamic> dropDownLists;
  final String productName;
  final String? imageUrl;

  UpdateInventory(this.dropDownLists, this.productName, this.imageUrl);

  @override
  State<UpdateInventory> createState() => _UpdateInventoryState();
}

String? _profileImageUrl = null;
bool isLoading = true;
final ImagePicker _imagePicker = ImagePicker();
// for storing and choosing image
File? imageFile;
String _currentProduct = "";
String _availableQuantity = "00";
String _currentProductPrice = "00";
String _totalQuantity = "00";

class _UpdateInventoryState extends State<UpdateInventory> {
  TextEditingController _productPriceController = TextEditingController();
  TextEditingController _productQuantityController = TextEditingController();
  TextEditingController _featureController = TextEditingController();
  Map<dynamic, dynamic> variantsMap = {};
  List<List<String>> tempList = [];
  List<dynamic> tempHintList = [];
  Map currentSelectedFeatures = {};
  Map currentSelectedFeature = {};
  List<String?> selectedValues = [];
  int mSelectedValue = 0;
  double _gResponsiveFontSize = 0.0;
  String previousSelectedValue = " ";
  Map<dynamic, dynamic> matchedVariant = {};
  int totalDropdowns = 0;
  int totalDropdownsToBeConsidered = 0;
  var matchedVariantKey = "";
  String currentProductName = "";
  bool hasInternet = false;
  var isDeviceConnected = false;
  bool isAlertDialogSet = false;
  var internetConnectionChecker = InternetConnectionChecker.createInstance();


  @override
  void initState() {
    super.initState();
    print("update inventory class");

    FirebaseDatabase.instance.ref(Constants.databaseRefStringMyTrade).child(Constants.databaseRefStringEnv)
        .child('ProductCount').child(Constants.myUserId).child('TotalProductCount').keepSynced(true);

    _currentProduct = widget.productName;

    _initialize();
  }

  showAlertDialogForNoInternet() async {
    isAlertDialogSet = true;
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
                  isAlertDialogSet = false;
                  isDeviceConnected =
                  await internetConnectionChecker.hasConnection;
                  //  id there is no internet connection and the dialog box is not showing
                  if (!isDeviceConnected && !isAlertDialogSet) {
                    showAlertDialogForNoInternet();
                  }
                },
                child: Text("OK"))
          ],
        ));
  }

  Future<void> _getConnectivity() async {
    isDeviceConnected = await internetConnectionChecker.hasConnection;
    if (!isDeviceConnected && !isAlertDialogSet) {
      showAlertDialogForNoInternet();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _profileImageUrl = null;
  }



  Future<void> _initialize() async {
    print("UpdateInvnetory initializing");
    currentProductName = widget.productName;

    print("updateInvnetory widget.drodpwon is ${widget.dropDownLists}");

    if(widget.imageUrl != null){
      _profileImageUrl = widget.imageUrl;
    }


    await getProductVariants();

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
    totalDropdowns = tempList.length;
    print("UpdateInventory init totalDropDowns ${totalDropdowns}");

    setState(() {
      isLoading = false;
    });
  }

  getProductVariants() async {
    variantsMap = await MyFirebase.getProductVariants(widget.productName,Constants.myUserId);
    print("UpdateInvnetroy get product variants fetching products successful");
    print(
        "UpdateInventory the products variants are $variantsMap");
  }

  @override
  Widget build(BuildContext context) {
    print(" inside widget ${widget.dropDownLists.keys.toList()}");
    print("inside widget values ${widget.dropDownLists.values.toList()}");
    // get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double responsiveFontSize = Constants.baseFontSize * (screenWidth / 375);
    _gResponsiveFontSize = responsiveFontSize;
    return isLoading
        ? Container(
            child: Constants.showSpinKit(),
          )
        : Scaffold(
            appBar: AppBar(
              leading: IconButton(onPressed: (){
                Navigator.pop(context);
                context.read<DataBloc>().add(FetchData(Constants.blocStringGetMyProducts, Constants.myUserId));
              }, icon: Icon(Icons.arrow_back_ios, color: AppColors.white,)),
              title: Text("${widget.productName}", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightGray),),
              actions: [
                IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EditInventory(
                                  widget.productName, widget.dropDownLists, _profileImageUrl ?? "")));
                    },
                    icon: Icon(
                      Icons.add_box_outlined,
                      color: AppColors.lightGray,
                    )),
                IconButton(
                    onPressed: () async {
                      _getConnectivity();
                      if(!isDeviceConnected){
                        _getConnectivity();
                      }else{
                        bool allAreDefault = currentSelectedFeatures.values.every((val) => val == "-");

                        if(allAreDefault && imageFile == null){
                          Constants.showAToast("Please Select Some Features", context);
                        }else{
                          if (imageFile != null && (_productQuantityController.text.isEmpty && _productPriceController.text.isEmpty)) {
                            showDialog(context: context, builder: (context) => Constants.showSpinKit());
                            // only image has to be updated
                            await _uploadImageToFirebase(imageFile, context);
                            imageFile = null;
                            await getProductVariants();
                            Navigator.pop(context);
                            Constants.showAToast("Image Successfully Updated", context);

                          }else
                          if ((_productQuantityController.text.isNotEmpty &&
                              _productPriceController.text.isNotEmpty) && imageFile == null) {
                            showDialog(context: context, builder: (context) => Constants.showSpinKit());

                            // only inventory to be updated
                            print("updateInventory about to save inventory");

                            await MyFirebase.saveInventory(
                                widget.productName,
                                _productPriceController.text,
                                _productQuantityController.text,
                                currentSelectedFeatures,
                                matchedVariantKey);
                            await getProductVariants();
                            // dismiss dialog
                            Navigator.pop(context);
                            setState(() {
                              _productPriceController.text = "";
                              _productQuantityController.text = "";
                              _totalQuantity = "";
                              fetchTheVariant();
                            });

                          }else if((_productPriceController.text.isNotEmpty && _productQuantityController.text.isNotEmpty) && imageFile != null){
                            showDialog(context: context, builder: (context) => Constants.showSpinKit());
                            //   update both image and inventory
                            await _uploadImageToFirebase(imageFile, context);
                            imageFile = null;

                            await MyFirebase.saveInventory(
                                widget.productName,
                                _productPriceController.text,
                                _productQuantityController.text,
                                currentSelectedFeatures,
                                matchedVariantKey);
                            await getProductVariants();
                            setState(() {
                              _productPriceController.text = "";
                              _productQuantityController.text = "";
                              _totalQuantity = "";
                              fetchTheVariant();
                            });



                            // dismiss dialog
                            Navigator.pop(context);
                            Constants.showAToast("Data successfully Updated", context);
                          }

                          else {
                            Constants.showAToast(
                                "One Of The Fields Is Empty", context);
                          }
                        }
                      }

                    },
                    icon: Icon(
                      Icons.check,
                      color: AppColors.lightGray,
                    ))
              ],
              centerTitle: true,
              backgroundColor: AppColors.steelBlue,
            ),
            body: SafeArea(
                child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Stack(children: [
                        ClipRRect(
                          child: imageFile != null
                              ? Container(
                            height: 100,
                            width: 100,
                            child: Image.file(
                              imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Container(
                              height: 100,
                              width: 100,
                              color: _profileImageUrl == null
                                  ? AppColors.lightGray
                                  : null,
                              child: _profileImageUrl != null
                                  ? _profileImageUrl!.isNotEmpty
                                  ? Image(
                                image: CachedNetworkImageProvider(_profileImageUrl!, cacheManager: CustomCacheManager()),
                                fit: BoxFit.cover,
                              )
                                  : null
                                  : null),
                        ),
                        Positioned(
                            bottom: -14,
                            right: -15,
                            child: IconButton(
                              onPressed: () {
                                _showModalBottomSheet();
                              },
                              icon: Icon(Icons.add_box),
                              color: AppColors.charcoal,
                            ))
                      ]),
                      SizedBox(
                        width: 15,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Available Quantity :", style: TextStyle(color: AppColors.charcoal, fontSize: 16, fontWeight: FontWeight.bold),),
                              SizedBox(width: 4),
                              Text("$_availableQuantity", style: TextStyle(color: AppColors.charcoal, fontSize: 16, fontWeight: FontWeight.bold))
                            ],
                          ),
                          Row(
                            children: [
                              Text(" Current Product Price:", style: TextStyle(color: AppColors.charcoal, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(
                                width: 4,
                              ),
                              Text("$_currentProductPrice", style: TextStyle(color: AppColors.charcoal, fontSize: 16, fontWeight: FontWeight.bold))
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: 10,),
                  textField("New Product Price", _productPriceController, false),
                  SizedBox(
                    height: 10,
                  ),
                  textField("Add New Quantity", _productQuantityController, true),
                  Align(
                    alignment: Alignment.centerLeft,
                      child: Text("Total Quantity : ${_totalQuantity}")),
                  Expanded(
                    child: ListView.builder(
                        itemCount: tempList.length,
                        itemBuilder: (context, index) {
                          return DropDownMenu(
                              tempHintList[index], tempList[index], index);
                        }),
                  )
                ],
              ),
            )));
  }

  Widget DropDownMenu(String hint, List list, int index) {
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
          previousSelectedValue = selectedValues[index] ?? " ";
          selectedValues[index] = value;
          print(
              "UpdateInventory current selected value in this index is ${previousSelectedValue}");
          print("UpdateInventory selected valus is ${value}");

          assignCurrentValues(hint, selectedValues[index]!, index);

          print("the length of selected value is ${selectedValues.length}");
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

  Widget textField(String label, TextEditingController controller, bool isAddNewQuantity) {
    return TextField(
      cursorColor: AppColors.charcoal,
      keyboardType: TextInputType.number,
      textCapitalization: TextCapitalization.words,
      onChanged: (value){
        print("UpdateInvnetory the user typed $value");
        if(isAddNewQuantity){

        setState(() {
         if(controller.text.isNotEmpty){
           _totalQuantity =  "${int.parse(value)+ int.parse(_availableQuantity)})";
           print("UpdateInvnetory after entering th value $label");
         }else{
           _totalQuantity = "";
         }
        });

        }
      },
      controller: controller,
      decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.charcoal)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: AppColors.steelBlue.withOpacity(0.8), width: 2)),
          labelText: label,
          border: OutlineInputBorder(),
          labelStyle: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.charcoal)),
    );
  }
  //
  assignDefaultValues(List<dynamic> hintList) {

    print("UpdateInvnetory ${selectedValues}");
    print("the hint is $hintList");

    for(String hint in hintList){
      currentSelectedFeatures.addAll({hint: "-"});
    }
    print("UpdateInvnetory assignDefaultValues are  ${currentSelectedFeatures} ");

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
    print("updateInventory selected values are at fetch the variant $selectedValues");

    print(
        "UpdateInventory fetchTheVariant previous selected value is ${previousSelectedValue}");
    // bool allSelected = selectedValues
    //     .every((value) => value != "-" && value != previousSelectedValue);


      Map<dynamic, dynamic> foundVariant = {};

      for (var entry in variantsMap.entries) {

        final variantValues = entry.value;
        print("updateInventory fetchTheVariant  variant values ${variantValues}");

        bool isMatched = currentSelectedFeatures.entries.every((featureEntry) {
          if(featureEntry.key == "productQuantity") return true;
          if(featureEntry.key == "productPrice") return true;
          final key = featureEntry.key;
          final selectedValue = featureEntry.value;
          final variantValue = variantValues[key];

          print("key: $key, selected: $selectedValue, variant: $variantValue");


          return variantValue == selectedValue || variantValue == "-";
        });

        if (isMatched) {
          matchedVariantKey = entry.key;
          print("UpdateInventory isMatched ${matchedVariantKey}");
          foundVariant = variantValues;
          print("the found variant is ${foundVariant}");
          setState(() {

            final aq = foundVariant['productQuantity'] ?? "";
            final npp = foundVariant['productPrice'] ?? "";

            _availableQuantity = aq.toString();
            _currentProductPrice = npp;
            matchedVariant = foundVariant;
          });
          break;

        }else{
          matchedVariantKey = "";
          matchedVariant = {};
          if(_availableQuantity != "00" && _currentProductPrice != "00"){
            setState(() {
              _availableQuantity = "00";
              _currentProductPrice = "00";

            });
          }
        }
      }
  }

  _showModalBottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            color: AppColors.steelBlue.withOpacity(0.5),
            height: MediaQuery.of(context).size.height / 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // gallery icon
                IconButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      _chooseImage(ImageSource.gallery);
                    },
                    icon: Icon(
                      Icons.image,
                      color: Colors.black,
                      size: 50,
                    )),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _chooseImage(ImageSource.camera);
                    },
                    icon: Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 50,
                    ))
              ],
            ),
          );
        });
  }

  _chooseImage(ImageSource source) async {
    await Constants.requestPermissions();

    var storage = await Permission.storage.status;
    var photos = await Permission.photos.status;
    if (storage.isGranted || photos.isGranted) {
      try {
        // picking the image from the source, in this case gallery
        final pickedFile = await _imagePicker.pickImage(source: source);

        if (pickedFile != null) {
          // getting the selected image as a file
          setState(() {
            imageFile = File(pickedFile.path);
            print("the selected image is $imageFile");
          });
        }
      } catch (e) {
        print("image picking failed");
      }
    }
  }

   _uploadImageToFirebase(File? imageFile, BuildContext context) async {
    // if new
    if (imageFile != null) {
      // get the size of the (image) file with
      var imageFileSize = await imageFile.length();
      if (imageFileSize > Constants.maxSizeInBytesForImageUpload) {
        //   compress the image to 200kb
        imageFile = await Constants.compressImageFile(imageFile, 75);
      }
      // if there has been any error in compressing the file then null will be returned by the catch block
      if (imageFile != null) {
        //   create a unique file for uploading to firebase

        var fileName =
            "${Constants.stringProductImages} ${currentProductName}";
        print(fileName);
        //   get the reference to firebase storage
        Reference firebaseStorageRef = FirebaseStorage.instance
            .ref()
            .child('myTrade/productImages/${Constants.myUserId}/$fileName');
        print("the firebase reference storage is $firebaseStorageRef");

        try {
          // upload task represents the ongoing upload process.
          // uploading the image file into storage.
          UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
          print("the upload task $uploadTask");

          //   getting the snapshot from upload task
          TaskSnapshot snapshot = await uploadTask;

          //   getting the url of the profile image
          _profileImageUrl = await snapshot.ref.getDownloadURL();
          print("profile profileImageUrl = $_profileImageUrl");

          await MyFirebase.updateProductImage(_currentProduct, _profileImageUrl ?? "");
        } catch (e) {
          Navigator.pop(context);
          Constants.showAToast(
              "could not upload image please try again later", context);
        }
      } else {
        Navigator.pop(context);
        Constants.showAToast(
            "could not upload the image please try again later", context);
      }
    } else {
      return;
    }
  }
}
