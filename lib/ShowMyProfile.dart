import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_trade/BLOC/DataBloc.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Home.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/Utils/Constants.dart';
import 'package:permission_handler/permission_handler.dart';

import 'BLOC/DataState.dart';
import 'Models/UserProfile.dart';
import 'Utils/CustomCacheManager.dart';

class ShowMyProfile extends StatefulWidget {
  const ShowMyProfile({super.key});

  @override
  State<ShowMyProfile> createState() => _ShowMyProfileState();
}

String _profileImageUrl = "";
String _userId = "";
bool defaultValuesAssigned = false;
File? _imageFile;
final ImagePicker _imagePicker = ImagePicker();

class _ShowMyProfileState extends State<ShowMyProfile> {
  TextEditingController _nameOfTheShopController = TextEditingController();
  TextEditingController _nameOfTheOwnerController = TextEditingController();
  TextEditingController _profileTypeController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    MyFirebase.getMyProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.steelBlue,
        title: Text(
          "Profile",
          style: TextStyle(
              color: AppColors.lightGray, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (context) => Constants.showSpinKit(),
                );

                if(_imageFile != null){
                  await _uploadImageToFirebase(_imageFile, context);
                }
                //         update User Profile
                UserProfile userProfile = UserProfile(
                    nameOfTheOwner: _nameOfTheOwnerController.text,
                    nameOfTheShop: _nameOfTheShopController.text,
                    profileType: _profileTypeController.text,
                    profileImageUrl: _profileImageUrl,
                    userId: _userId,
                  phoneNumber: _phoneNumberController.text

                );


              await  MyFirebase.updateUserProfile(userProfile, _userId);
              //   dismiss spin kit
                Navigator.pop(context);
                Constants.showAToast("Details Updated", context);
              },
              icon: Icon(Icons.check, color: AppColors.white,))
        ],
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
              padding: EdgeInsets.all(10),
              child: Expanded(child:
                  BlocBuilder<DataBloc, DataState>(builder: (context, state) {
                if (state.dataStatus == DataStatus.success) {
                  return showdata(state.userProfile);
                } else {
                  return CircularProgressIndicator();
                }
              })))),
    );
  }

  Widget showdata(UserProfile? userProfile) {
    bool isDataNull = userProfile == null;

    if (!isDataNull) {
      assignDefaultValues(userProfile);
    }
    return isDataNull
        ? Scaffold(
            body: SafeArea(
                child: Center(
              child: Text("No Data"),
            )),
          )
        : defaultValuesAssigned
            ? Scaffold(
                body: SafeArea(
                  child: Column(
                    children: [
                      Stack(children: [

                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child:_imageFile != null ? Container(
                            height: 200,
                            width: 200,
                            color:  null,
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          ) :
                        //       imageFile is null
                          _profileImageUrl.isEmpty ?
                          Container(
                            height: 200,
                            width: 200,
                            color: AppColors.greyMedium,
                            child: null,
                          ) :
                          Container(
                            height: 200,
                            width: 200,
                            color: AppColors.greyMedium,
                            child: Image(image: CachedNetworkImageProvider(_profileImageUrl, cacheManager: CustomCacheManager()), fit: BoxFit.cover,),
                          )

                        ),

                        Positioned(
                            bottom: -15,
                            left: 162,
                            child: IconButton(
                                onPressed: () {
                                  _showModalBottomSheet();
                                },
                                icon: Icon(Icons.add_box, color: AppColors.charcoal,)))
                      ]),
                      SizedBox(
                        height: 15,
                      ),
                     Expanded(
                       child: SingleChildScrollView(
                         child: Column(
                           children: [
                             textField("Name Of The Shop", _nameOfTheShopController, false),
                             SizedBox(
                               height: 15,
                             ),
                             textField("Name Of THe Owner", _nameOfTheOwnerController, false),
                             SizedBox(
                               height: 15,
                             ),
                             textField("Profile Type", _profileTypeController, true),
                             SizedBox(height: 15,),
                             textField("Phone Number", _phoneNumberController, true)
                           ],
                         ),
                       ),
                     )
                    ],
                  ),
                ),
              )
            : Scaffold(
                body: SafeArea(
                    child: Center(
                  child: CircularProgressIndicator(),
                )),
              );
  }

  Widget textField(String label, TextEditingController controller, bool isProfileType) {
    return InkWell(
      onTap: (){
        if (isProfileType) {
          Constants.showAToast("Profile Type cannot be changed", context);
        }
      },
      child: TextField(
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
       readOnly: isProfileType ? true : false,
        onChanged: (value) {

        },
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
      ),
    );
  }

  Future<void> assignDefaultValues(UserProfile? userProfile) async {
    if (userProfile != null) {
      _nameOfTheShopController.text = userProfile.nameOfTheShop ?? "";
      _nameOfTheOwnerController.text = userProfile.nameOfTheOwner ?? "";
      _profileTypeController.text = userProfile.profileType ?? "";
      _profileImageUrl = userProfile.profileImageUrl ?? "";
      _phoneNumberController.text = userProfile.phoneNumber ?? "";
      _userId = userProfile.userId ?? "";
    }

    setState(() {
      defaultValuesAssigned = true;
    });
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
            "${Constants.stringProductImages}  shopProfileImage";
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

  _showModalBottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            color: AppColors.veryLightTeal,
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
            _imageFile = File(pickedFile.path);
            print("the selected image is $_imageFile");
          });
        }
      } catch (e) {
        print("image picking failed");
      }
    }
  }
}
