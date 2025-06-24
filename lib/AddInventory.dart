import 'dart:ffi';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/ManageStock.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Utils/Constants.dart';

class Addinventory extends StatefulWidget {

  const Addinventory({super.key});



  @override
  State<Addinventory> createState() => _AddinventoryState();
}


int currentTextFieldPosition = -2;
int featureNumber = 0;
List<Widget> featureFields = [];
final Map<String, List<String>> featuresGroup = {};
TextEditingController _subFeatureController = TextEditingController();
TextEditingController _productNameController = TextEditingController();
TextEditingController _featureController = TextEditingController();
String _profileImageUrl = "";


class _AddinventoryState extends State<Addinventory> {

@override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    currentTextFieldPosition = -2;
    _productNameController.text = "";
  }

  @override
  void initState() {
    super.initState();
    initializeTextFields();
    print("addInvnetory initial currentTextFieldPosition ${currentTextFieldPosition}");
  }
  void initializeTextFields(){
     featureFields = [];
  }

  void reInitializeFields(){
    for(var key in featuresGroup.keys){
      featureFields.add(container(key));
      featureFields.add(SizedBox(height: 15,));

    }
  }

  final ImagePicker _imagePicker = ImagePicker();

  // for storing and choosing image
  File? imageFile;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Invnetory", style: TextStyle(color: AppColors.lightGray, fontWeight: FontWeight.bold),),
        leading: TextButton(onPressed: (){
          print("addInvnetory popping ${currentTextFieldPosition}");
          Navigator.pop(context);
        }, child: Icon(Icons.arrow_back_ios,color: AppColors.lightGray,), ),
        actions: [
          IconButton(onPressed: () async {

            if(_productNameController.text.isNotEmpty){
              showDialog(context: context, builder: (spinkitContext) => Constants.showSpinKit());
              await  _uploadImageToFirebase(imageFile, context);
              await  MyFirebase.saveProduct(_productNameController.text, featuresGroup, _profileImageUrl);

              // dismiss spin kit
              Navigator.pop(context);

              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ManageStock()));
            }else{
              Constants.showAToast("Enter Product Name", context);
            }

          }, icon: Icon(Icons.check, color: AppColors.lightGray,))
        ],
        centerTitle: true,
        backgroundColor: AppColors.steelBlue),
      body: SafeArea(child:
      Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SingleChildScrollView(
          child: Column(

            children: [
              Stack(
                  children:[
                   ClipRRect(
                      child: Container(
                        color: imageFile == null ? AppColors.lightGray : null,
                        width: 150,
                        height: 150,
                        child: imageFile != null ?
                        Image.file(imageFile!, fit: BoxFit.cover,) : null,
                      ),

                    ),

                    Positioned(
                        bottom: -14,
                        right: -15,
                        child: IconButton(onPressed: (){
                          _showModalBottomSheet();
                        }, icon: Icon(Icons.add_box), color: AppColors.charcoal,))
                  ]),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(onPressed: (){
                    showDialog(context: context, builder: (BuildContext context){
                      return AlertDialog(
                        content: TextField(
                          textCapitalization: TextCapitalization.words,
                          controller: _featureController,
                          cursorColor: AppColors.charcoal,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(width: 2, color: AppColors.charcoal)
                              ),
                            label: Text("Feature Name", style: TextStyle(color: AppColors.charcoal),)
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: (){
                           String name  = _featureController.text;
                           if(_featureController.text.isNotEmpty && !featuresGroup.containsKey(name)){
                             print("AddInvnetory addFeature ${_featureController.text}");
                             featuresGroup[name] = [];
                             print(" addInvnetory currenttextfieldposition ${currentTextFieldPosition}");
                             setState(() {
                               Navigator.pop(context);
                               _featureController.text = "";
                               currentTextFieldPosition +=2;
                               featureNumber++;
                               featureFields.insertAll(currentTextFieldPosition, [
                                 container("${name}"),
                                 SizedBox(height:15)
                               ]);
                             });
                           }

                          }, child: Text("Done"))
                        ],
                      );
                    });

                  }, icon: Icon(Icons.add_box_outlined, color: AppColors.charcoal, size: 30,))
                ],
              ),
              SizedBox(height: 10,),
              textField("Product Name"),
              SizedBox(height: 10,),
              // ... unwraps the list
              ...featureFields


            ],
          ),
        ),

      )

      ),
    );
  }


  Widget container(String label){
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: AppColors.greyMedium.withOpacity(0.4),
          border: Border.all(
              color: AppColors.charcoal,
              width: 2
          ),
          borderRadius: BorderRadius.circular(4)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () {
                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(builder: (context, setState){
                            return AlertDialog(
                              title: Column(
                                children: [
                                  Text(label),
                                  TextField(
                                    textCapitalization: TextCapitalization.words,
                                    controller: _subFeatureController,
                                    cursorColor: AppColors.charcoal,
                                    decoration: InputDecoration(
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(width: 2, color: AppColors.charcoal)
                                      ),
                                        border: OutlineInputBorder(),
                                        label: Text("Sub Feature", style: TextStyle(color: AppColors.charcoal),)),

                                  ),
                                ],
                              ),
                              content: SizedBox(
                                height: 200,
                                width: 200,
                                child: ListView.builder(
                                    itemCount: featuresGroup[label]?.length,
                                    itemBuilder: (context, index){
                                      return Container(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              Text(featuresGroup[label]?[index] ?? "No Category", textAlign: TextAlign.center,),
                                              IconButton(onPressed: (){
                                                print("EditInventory removing ${featuresGroup[label]?[index]}");
                                               setState((){
                                                 //  if featuresGroup is null no error will be thrown
                                                 featuresGroup[label]?.removeAt(index);
                                               });
                                              }, icon:Icon(Icons.delete))
                                            ],
                                          )

                                      );
                                    }),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);

                                    },
                                    child: Text("Done")),

                                TextButton(
                                    onPressed: () {

                                      featuresGroup[label]
                                          ?.add(_subFeatureController.text);

                                      setState(() {
                                        _subFeatureController.clear();
                                      });
                                    },
                                    child: Text("Add"))
                              ],
                            );
                          });
                        });
                  },
                  icon: Icon(Icons.add_box_outlined)),

              SizedBox(width: 10,),
              Text(label, style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold, fontSize: 16),),

            ],
          ),
          IconButton(onPressed: (){
            showDialog(context: context, builder: (BuildContext context){
              return AlertDialog(
                title: Text("Are you sure you want to delete this feautre?"),
                actions: [
                  TextButton(onPressed: (){
                    // delete the feature from all the existing variants

                    Navigator.pop(context);
                    print("AddInventroy onDelete before deleting ${featuresGroup}");
                    setState(() {
                      featuresGroup.remove(label);
                      featureFields.clear();
                      currentTextFieldPosition -=2;
                      reInitializeFields();




                    });
                    print("AddInventory onDelete after deleting ${featuresGroup}");
                  }, child: Text("Yes")),
                  TextButton(onPressed: (){
                    // dismiss the dialog
                    Navigator.pop(context);
                  }, child: Text("No"))
                ],
              );
            });
          }, icon: Icon(Icons.delete, color: AppColors.charcoal,))

        ],
      ),
    );
  }

  Widget textField(String label){
    return TextField(
      style: TextStyle(fontWeight: FontWeight.bold),
      textCapitalization: TextCapitalization.words,
      controller:  _productNameController,
      cursorColor: AppColors.charcoal,
      decoration: InputDecoration(

        filled: true,
        fillColor: AppColors.greyMedium.withOpacity(0.4),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.charcoal)
          ),

          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.charcoal, width: 2)
          ),
          labelText: label,
          border: OutlineInputBorder(),
          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.charcoal)
      ),

    );
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
  //
  static _uploadImageToFirebase(
      File? imageFile, BuildContext context) async {
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
        var fileName = "${Constants.stringProductImages} ${_productNameController.text}";
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
          print("profile productImageUrl = $_profileImageUrl");


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
