import 'dart:ffi';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/Utils/Constants.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Models/UserProfile.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Home.dart';

class CreateProfile extends StatefulWidget {
  String phoneNumber;

  CreateProfile(this.phoneNumber);

  @override
  State<CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {
  bool selectedTraderType = false;
  bool isRetailer = false;
  final ImagePicker _imagePicker = ImagePicker();
  TextEditingController _nameOfTheShopController = TextEditingController();
  TextEditingController _nameOfTheOwnerController = TextEditingController();

  // for storing and choosing image
  File? imageFile;
  String _profileImageUrl = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseDatabase.instance
        .ref(Constants.databaseRefStringMyTrade)
        .child(Constants.databaseRefStringEnv)
        .child('TotalUserCount')
        .child('UserCount')
        .keepSynced(true);
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

    return selectedTraderType
        ? createTrader()
        : selectTraderType(screenHeight, screenWidth);
  }

  Widget selectTraderType(double screenHeight, double screenWidth) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Create Profile",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.lightGray,
                fontFamily: 'Roboto'),
          ),
          centerTitle: true,
          backgroundColor: AppColors.steelBlue,
        ),
        body: SafeArea(
            child: Center(
              child: Container(
                height: screenHeight * 0.5,
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.charcoal, width: 2)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedTraderType = true;
                              isRetailer = false;
                            });
                          },
                          child: Image.asset(
                            'assets/images/distributor.png',
                            width: screenWidth * 0.3,
                          ),
                        ),
                        Text("Distributor")
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedTraderType = true;
                              isRetailer = true;
                            });
                          },
                          child: Image.asset(
                            'assets/images/retailer.png',
                            width: screenWidth * 0.3,
                          ),
                        ),
                        Text("Retailer")
                      ],
                    )
                  ],
                ),
              ),
            )));
  }

  Widget createTrader() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isRetailer ? "Retailer" : "Distributor",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.lightGray),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () async {

                if (_nameOfTheShopController.text.isNotEmpty &&
                    _nameOfTheOwnerController.text.isNotEmpty) {


                  await MyFirebase.setUserProfile(UserProfile(
                      nameOfTheOwner: _nameOfTheOwnerController.text,
                      nameOfTheShop: _nameOfTheShopController.text,
                      profileType: isRetailer ? "Retailer" : "Distributor",
                      profileImageUrl: _profileImageUrl,
                      userId:'',
                      phoneNumber: widget.phoneNumber));

                  // to get the user id.
                  await MyFirebase.getMyUserId();

                  Constants.showSpinKit();
                  if (imageFile != null) {
                    await _uploadImageToFirebase(imageFile, context);
                  }

                  // to check if the user is a distributor
                  await MyFirebase.getMyProfileDetails();

                  await MyFirebase.updateShopImageUrl(_profileImageUrl);

                  await MyFirebase.setUserIdForProductCount();

                  // dismiss spinkit
                  Navigator.pop(context);

                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => Home()));
                } else if (_nameOfTheOwnerController.text.isEmpty) {
                  Constants.showAToast(
                      "Please Enter Name Of The Owner", context);
                } else if (_nameOfTheShopController.text.isEmpty) {
                  Constants.showAToast(
                      "Please Enter Name of The Shop", context);
                }
              },
              icon: Icon(
                Icons.check,
                color: AppColors.lightGray,
              ))
        ],
        backgroundColor: AppColors.steelBlue,
      ),
      body: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(children: [
                    ClipRRect(
                      child: Container(
                        height: 200,
                        width: 200,
                        color: imageFile != null ? null : AppColors.greyMedium,
                        child: imageFile != null
                            ? Image.file(imageFile!, fit: BoxFit.cover)
                            : null,
                      ),
                    ),
                    Positioned(
                        bottom: -15,
                        left: 162,
                        child: IconButton(
                            onPressed: () {
                              _showModalBottomSheet();
                            },
                            icon: Icon(Icons.add_box)))
                  ]),
                  SizedBox(
                    height: 15,
                  ),
                  textField("Name Of The Shop", _nameOfTheShopController),
                  SizedBox(
                    height: 15,
                  ),
                  textField("Name Of The Owner", _nameOfTheOwnerController),
                  SizedBox(
                    height: 15,
                  ),
                ],
              ),
            ),
          )),
    );
  }

  Widget textField(String label, TextEditingController controller) {
    return TextField(
      cursorColor: AppColors.charcoal,
      style: TextStyle(fontWeight: FontWeight.bold,),
      textCapitalization: TextCapitalization.words,
      controller: controller,
      decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.charcoal)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.charcoal, width: 2)),
          labelText: label,
          border: OutlineInputBorder(),
          labelStyle: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.charcoal)),
    );
  }

  _showModalBottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            color: AppColors.steelBlue.withOpacity(0.5),
            height: MediaQuery
                .of(context)
                .size
                .height / 4,
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

        var fileName = "${Constants.stringProductImages}  shopProfileImage";
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
        } catch (e) {
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
