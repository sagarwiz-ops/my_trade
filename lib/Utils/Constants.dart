

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart' as cs;
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class Constants {

  // define a base font size for screen size responsive UI.
  static double baseFontSize = 20.0;


  static const databaseRefStringMyTrade = "MyTrade";
  static const databaseRefStringEnv = "Dev";
  static const stringDbNodeInventory = "Inventory";
  static const stringDbNodeFollowRequests = "FollowRequests";
  static const stringDbNodeValidatedNumbers = "ValidatedNumbers";
  static const stringDbNodeMyFollowers = "MyFollowers";
  static const stringDbNodeUsers = "Users";
  static const stringProductImages = "ProductImages";
  static String stringProductNumberForImage = "0";
  static String myUserId = "";
  static String userType = "";
  static String?  stringNameOfTheBusiness = "";
  static String? blocStringGetAllRetailers = "getAllRetailers";
  static String? blocStringGetAllDistributors = "getAllDistributors";
  static String? blocStringGetOrders = "getOrders";
  static String? blocStringGetMyProducts = "getMyProducts";
  static String? blocStringGetMyProfileData = "getMyProfileData";
  static bool isDistributor = false;
  static bool hasJustLoggedIn = false;
  static bool isFirstRunTransactionForLogin = false;
  static Map<String, dynamic> productNameImageUrl = {};
  static late double  gResponsiveFontSize;


  // limiting the size to 200 kb
  static const int maxSizeInBytesForImageUpload = 200 * 1024;


  static requestPermissions() async {
    // for android devices
    if (Platform.isAndroid) {
      //   get the android version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      // if the android version is less than or equal to 12
      if (androidInfo.version.sdkInt <= 32) {
        var galleryPermission = await Permission.photos.status;
        if (!galleryPermission.isGranted) {
          // ask for permission
          Permission.storage.request();
        }
      } else {
        var galleryPermission = await Permission.photos.status;
        if (!galleryPermission.isGranted) {
          Permission.photos.request();
        }
      }
    }
  }

  static void showAToast(String toastText, BuildContext context) {
    showToast(toastText,
        context: context,
        position: const StyledToastPosition(align: Alignment.topCenter),
        curve: Curves.easeInOut,
        backgroundColor: AppColors.white,
        textStyle: TextStyle(color: Colors.black, fontFamily: 'Roboto'),
        duration: Duration(seconds: 4));
  }

  static  showSpinKit(){
    return Container(
      color: AppColors.lightGray,
      child: (Center(
        child: SpinKitWaveSpinner(
          waveColor: AppColors.primary.withOpacity(0.5),
          trackColor: AppColors.greyMedium.withOpacity(0.8),
          color: AppColors.primary.withOpacity(0.8),
          size: 150,
        ),
      )),
    );
  }


  static Future<File?> compressImageFile(File file, int imageQuality) async {
    try{
      int previousQuality = imageQuality;
      if(imageQuality == 0){
        imageQuality =5;
      }
      File f;
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        //   absolute path of the image
          file.absolute.path,
          // new/target path of the compressed image
          '${file.absolute.path}_compressed.jpg',
          quality: imageQuality,
          minWidth: 800,
          minHeight: 450);

      if (compressedFile != null) {
        f = File(compressedFile.path);
        var sizeOfTheCompressedFile = await compressedFile.length();
        if (sizeOfTheCompressedFile <= Constants.maxSizeInBytesForImageUpload) {
          print(
              " the image has been compressed, size of the compressed Image is $sizeOfTheCompressedFile");
          return f;
        } else {
          print("compressed file is still larger than 200 kb ${sizeOfTheCompressedFile/1024}");
          int compressMore = previousQuality - 5;
          return compressImageFile(f, compressMore);
        }
      }
    }catch(e){
      print("${e}");
    }
    return null;
  }


  static makePhoneCall(String phoneNumber) {
    final Uri launchUriForCall = Uri(scheme: 'tel', path: phoneNumber);
    launchUrl(launchUriForCall);
  }

  static launchWhatsApp(String phoneNumber, String message) async {
    final Uri whatsAppUri = Uri(
        scheme: 'https',
        path: "+91${phoneNumber}",
        host: 'wa.me',
        queryParameters: message.isNotEmpty ? {'text': message} : null);
    if (await canLaunchUrl(whatsAppUri)) {
      launchUrl(whatsAppUri);
    } else {

    }
  }

  static Future<PermissionStatus>checkIfPermissionForAccessToContactsHAsBeenGranted() async {
    return  Permission.contacts.status;
  }


 static  Future<void> requestContactsWithDialog(BuildContext context) async {
   final status = await checkIfPermissionForAccessToContactsHAsBeenGranted();
   if(status.isGranted){

   }else{
     // Step 1: Show your own dialog first
     showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) {
         return AlertDialog(

           title: Text('Access Contacts'),
           content: Text('To explore retailers and distributors you know, we need access to your contacts.'),
           actions: [

             TextButton(
               onPressed: () async {
                 Navigator.of(context).pop(); // Close the dialog

                 // Step 2: Ask for actual permission
                 final status = await Permission.contacts.request();

                 // Step 3: React to result
                 if (status.isGranted) {
                   Constants.showAToast("✅ Permission Granted", context);
                   // Fetch contacts or whatever you want next
                 } else if (status.isPermanentlyDenied) {
                   Constants.showAToast("⚠️ Permission permanently denied. Please enable it in settings.", context);
                   openAppSettings();
                 } else {
                   Constants.showAToast("❌ Permission Denied", context);
                 }
               },
               child: Text('OK'),
             ),
           ],
         );
       },
     );
   }
 }

 static Future<List<Contact>> getAllContacts() async {
    Iterable<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
    return contacts.toList();
  }

  static List<String> extractPhoneNumbers(List<cs.Contact> contacts) {
    final numbers = <String>[];

    for (var contact in contacts) {
      for (var phone in contact.phones ?? []) {
        var number = phone.number?.replaceAll(RegExp(r'\D'), '') ?? '';

        if (number.isEmpty) continue;

        // Remove leading 0 if present (e.g. 09876543210 -> 9876543210)
        if (number.startsWith('0') && number.length == 11) {
          number = number.substring(1);
        }

        // Convert to +91 format if it's a 10-digit Indian number
        if (number.length == 10) {
          number = '+91$number';
        }

        // If already includes country code like 919876543210, convert to +91
        else if (number.length == 12 && number.startsWith('91')) {
          number = '+$number';
        }

        if (number.startsWith('+91') && number.length == 13) {
          numbers.add(number);
        }
      }
    }

    return numbers;
  }


  static Future<bool> checkIfTheCurrentUserExists() async {
    if (FirebaseAuth.instance.currentUser != null) {
      if (FirebaseAuth.instance.currentUser!.phoneNumber != null) {
        if (FirebaseAuth.instance.currentUser!.phoneNumber!.isNotEmpty) {
          return true;
        }
        return false;
      }
      return false;
    }
    return false;
  }


}


