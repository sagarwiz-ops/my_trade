import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:my_trade/Utils/Constants.dart';
import 'package:my_trade/Models/UserProfile.dart';
import 'package:my_trade/AddInventory.dart';

class MyFirebase {
  MyFirebase._();

  static var phoneNumber = FirebaseAuth.instance.currentUser!.phoneNumber;
  static Addinventory inv = Addinventory();

  static final DatabaseReference realTimeDbRef = FirebaseDatabase.instance
      .ref(Constants.databaseRefStringMyTrade)
      .child(Constants.databaseRefStringEnv);

  static Future setUserProfile(UserProfile userProfile) async {
    final uc = realTimeDbRef
        .child("TotalUserCount")
        .child("UserCount")
        .ref;

    DataSnapshot ee = await uc.get();
    print("MyFirebase ee is ${ee.value}");

    uc.runTransaction((uc) {
      if (uc != null) {
        print("MyFirebase setUserProfile uc is ${uc.toString()}");
        realTimeDbRef
            .child("Users")
            .child("$uc")
            .set(userProfile.copyWith(userId: uc.toString()).toJson());
        int uci = (uc as int ?? 0) + 1;
        MyFirebase.saveMobileNumber(uc.toString());
        return Transaction.success(uci);
      } else {
        print("MyFirebase setUserProfile uc is ${uc.toString()}");
        return Transaction.abort();
      }
    });
  }

  static updateUserProfile(UserProfile userProfile, String userId) {
    Map<String, dynamic> userMap = userProfile.toJson();
    realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(userId)
        .update(userMap);
  }

  static Future<void> updateShopImageUrl(String imageUrl) async {
    await realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .update({'profileImageUrl': imageUrl});
  }

  static Future<void> getMyUserId() async {
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeValidatedNumbers)
        .child(phoneNumber!)
        .once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      Constants.myUserId = data["userId"];
      print("mhy user id is ${Constants.myUserId}");
    }
  }

  static Future<UserProfile?> getMyProfileData() async {
    UserProfile? userProfile = null;
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      Map<String, dynamic> map =
      Map<String, dynamic>.from(snapshot.value as Map);
      print("MyFirebase getMyProfileData ${UserProfile.fromJson(map)}");
      return UserProfile.fromJson(map);
    } else {
      return null;
    }
  }

  static Future<void> getMyProfileDetails(bool isManager) async {
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      print("myProfile ${snapshot.value}");
      if (!isManager) {
        Constants.isDistributor = data["profileType"] == "Distributor";
      }
      print(
          "MyFirebase getMyProfileDetails isDistributor ${Constants
              .isDistributor} ");
      isManager ?
      Constants.stringNameOfTheBusiness = "${data["nameOfTheShop"]} [Manager]"
          : Constants.stringNameOfTheBusiness = data["nameOfTheShop"];
    } else {}
  }

  static saveMobileNumber(String userId) {
    realTimeDbRef
        .child("ValidatedNumbers")
        .child(phoneNumber.toString())
        .set({'userId': userId});
  }

  static Future<List<String>> checkMyFollowRequests() async {
    List<String> userIds = [];
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeFollowRequests)
        .child(Constants.myUserId)
        .once();
    DataSnapshot snapshot = event.snapshot;
    print(
        "MyFirebase checkMyFollowRequests follow Requests are ${snapshot
            .value}");
    if (snapshot.value != null) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      print("MyFirebase checkMyFollowRequests the data is $data");
      data.forEach((key, value) {
        userIds.add(key);
      });
    }

    return userIds;
  }

  static Future<List<UserProfile>> getAllRetailersFollowRequests() async {
    List<String> userIds = await MyFirebase.checkMyFollowRequests();

    // Use map to create a list of futures
    final futures = userIds.map((userId) async {
      DatabaseEvent event = await realTimeDbRef
          .child(Constants.stringDbNodeUsers)
          .child(userId.toString())
          .once();

      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        print(
            "MyFirebase getAllRetailersFollowRequests snapshot.value ${snapshot
                .value} ");
        Map<dynamic, dynamic> map1 = snapshot.value as Map<dynamic, dynamic>;
        Map<String, dynamic> map2 =
        map1.map((key, value) => MapEntry(key.toString(), value));
        print(
            "MyFirebase getAllRetailersFollowRequests user who has sent follow request: map1 $map1");
        print(
            "MyFirebase getAllRetailersFollowRequests user who has sent follow request: map2 $map2");
        return UserProfile.fromJson(map2);
      } else {
        return null; // If user not found
      }
    }).toList();

    // Wait for all async operations to complete
    final results = await Future.wait(futures);

    // Remove null entries if any
    return results.whereType<UserProfile>().toList();
  }

  static setFollowRequest(String userId) {
    // this will be done by the retailer
    realTimeDbRef
        .child(Constants.stringDbNodeFollowRequests)
        .child(userId)
        .child(Constants.myUserId)
        .set(true);
  }

  static Future<List<UserProfile>> getMyDistributors() async {
    List<String> userIds = [];
    List<UserProfile> userProfiles = [];
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .child("MyFollowing")
        .once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      print("MyFirebase getMyDistributors ${snapshot.value}");
      Map<dynamic, dynamic> myDistributors =
      snapshot.value as Map<dynamic, dynamic>;
      myDistributors.forEach((key, value) {
        userIds.add(key);
      });

      for (var userId in userIds) {
        DatabaseEvent event = await realTimeDbRef
            .child(Constants.stringDbNodeUsers)
            .child(userId)
            .once();
        DataSnapshot snapshot = event.snapshot;
        if (snapshot.value != null) {
          final raw = snapshot.value as Map<Object?, Object?>;
          Map<String, dynamic> map =
          raw.map((key, value) => MapEntry(key.toString(), value));

          print("MyFirebase getMyFollowers bbbbb ${map}");
          userProfiles.add(UserProfile.fromJson(map));
        }
      }
    }

    return userProfiles;
  }

  static Future<List<UserProfile>> getMyFollowers() async {
    List<String> userIds = [];
    List<UserProfile> userProfiles = [];
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .child(Constants.stringDbNodeMyFollowers)
        .once();
    DataSnapshot snapshot = event.snapshot;
    print("MyFirebase getMyFollowers the followers are  ${snapshot.value}");
    Map<dynamic, dynamic> myFollowers = snapshot.value as Map<dynamic, dynamic>;
    print("MyFirebase getMyFollowers myFollowers map ${myFollowers}");
    myFollowers.forEach((key, value) {
      userIds.add(key);
    });
    print("MyFirebase getMyFollowers followers ids are ${userIds}");

    for (var userId in userIds) {
      DatabaseEvent event = await realTimeDbRef
          .child(Constants.stringDbNodeUsers)
          .child(userId)
          .once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        final raw = snapshot.value as Map<Object?, Object?>;
        Map<String, dynamic> map =
        raw.map((key, value) => MapEntry(key.toString(), value));

        print("MyFirebase getMyFollowers bbbbb ${map}");
        userProfiles.add(UserProfile.fromJson(map));
      } else {
        print("MyFirebase getMyFollowers snapshot was null");
      }
      print(
          "MyFirebase getMyFollowers myUserProfiles ${userProfiles.first
              .nameOfTheShop}");
      return userProfiles;
    }
    return userProfiles;
  }

  static acceptFollowRequest(String retailersUserId) {
    realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .child(Constants.stringDbNodeMyFollowers)
        .child(retailersUserId)
        .set(true);

    realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(retailersUserId)
        .child("MyFollowing")
        .child(Constants.myUserId)
        .set(true);
  }

  static removeFollowRequestAfterAccepting(String userId) {
    realTimeDbRef
        .child(Constants.stringDbNodeFollowRequests)
        .child(Constants.myUserId)
        .child(userId)
        .remove();
  }

  static Future<List<UserProfile>> getAllDistributors() async {
    List<UserProfile> userProfiles = [];
    DatabaseEvent event = await realTimeDbRef
        .child("Users")
        .orderByChild("profileType")
        .equalTo("Distributor")
        .once();
    DataSnapshot snapshot = event.snapshot;
    print("myfirebase ${snapshot.value}");
    if (snapshot.value != null) {
      if (snapshot.value is Map) {
        Map map = snapshot.value as Map;
        map.forEach((key, value) {
          Map<String, dynamic> mm = Map<String, dynamic>.from(value);
          userProfiles.add(UserProfile.fromJson(mm));
        });
      }
    }
    return userProfiles;
  }

  static Future<void> saveInventory(String productName,
      String productPrice,
      String productQuantity,
      Map<dynamic, dynamic> features,
      String variantId) async {
    print("started saving inventory");

    int availableQuantity;
    int newQuantity;
    try {
      newQuantity = int.parse(productQuantity);
    } catch (Exception) {
      newQuantity = 0;
    }
    // getting all the variants
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child(productName)
        .once();
    DataSnapshot snapshot = event.snapshot;
    print("saveInventory snapshot is ${snapshot.value}");
    bool found = false;
    String? existingVariantId;

    if (snapshot.exists) {
      final variants = snapshot.value as Map;
      print("save inventory ${snapshot.value}");

      variants.forEach((key, value) {
        final variant = Map<String, dynamic>.from(value);

        // Remove quantity if it's not part of the "feature comparison"
        final comparisonVariant = Map.of(variant)
          ..remove("productQuantity")..remove("productPrice");

        if (mapEquals(comparisonVariant, features)) {
          found = true;
          existingVariantId = key;
        }
      });
    }

    if (variantId.isNotEmpty) {
      existingVariantId = variantId;

      // get previous stock
      DatabaseEvent event = await realTimeDbRef
          .child(Constants.stringDbNodeInventory)
          .child(Constants.myUserId)
          .child(productName)
          .child(existingVariantId!)
          .child('productQuantity')
          .once();
      DataSnapshot snapshot = event.snapshot;
      print("product Quantity is ${snapshot.value}");
      if (snapshot.value != null) {
        availableQuantity = int.parse(snapshot.value.toString());
      } else {
        availableQuantity = 0;
      }
      var finalQuantity = (availableQuantity + newQuantity).toString();
      features['productQuantity'] = finalQuantity;
      features['productPrice'] = productPrice;
      print("saveInvnetory updatedFeautres are ${features}");

      final Map<String, Object?> safeMap = features.map(
            (key, value) => MapEntry(key.toString(), value),
      );

      // update existing stock
      realTimeDbRef
          .child(Constants.stringDbNodeInventory)
          .child(Constants.myUserId)
          .child(productName)
          .child(existingVariantId!)
          .update(safeMap);
      print("MyFirebase saveInventory saving successful");
    } else {
      print("creating new variant with new features");
      //  create a new stock and add its features
      final pc = realTimeDbRef
          .child("ProductCount")
          .child(Constants.myUserId)
          .child("TotalProductCount")
          .ref;

      pc.runTransaction((pc) {
        if (pc != null) {
          features["productQuantity"] = productQuantity;
          features["productPrice"] = productPrice;
          realTimeDbRef
              .child(Constants.stringDbNodeInventory)
              .child(Constants.myUserId)
              .child(productName)
              .child("Variant$pc")
              .set(features);
          int pci = (pc as int ?? 0) + 1;
          print("MyFirebase saveInventory new variant saving successful");
          return Transaction.success(pci);
        } else {
          return Transaction.abort();
        }
      });
    }
  }

  static Future<void> saveProduct(String productName,
      Map<String, dynamic> lists, String productImageUrl) async {
    await realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child("Data")
        .child(productName)
        .set(lists);

    await MyFirebase.updateProductImage(productName, productImageUrl);
  }

  static updateProduct(String productName, Map<String, dynamic> lists) {
    realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child("Data")
        .child(productName)
        .update(lists);
  }

  static Future<void> updateAllTheVariantsWithTheNewFeature(String productName,
      List<String> featureNames) async {
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child(productName)
        .once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      Map<String, dynamic> variantsMap =
      Map<String, dynamic>.from(snapshot.value as Map);
      print("updateAllTheVariantsWithTheNewFeature variantsMap ${variantsMap}");

      for (String featureName in featureNames) {
        variantsMap.updateAll((variantId, variantData) {
          print("updateAllTheVariantsWithTheNewFeature inside updateAll");
          return {...variantData, featureName: "-"};
        });
      }

      realTimeDbRef
          .child(Constants.stringDbNodeInventory)
          .child(Constants.myUserId)
          .child(productName)
          .update(variantsMap);
    } else {
      print(
          "MyFirebase updateAllTheVariantsWithTheNewFeature No Variants to be updated");
    }
  }

  static Future<void> removeFeatureFromAllVariants(String productName,
      String featureName) async {
    // remove the feature from data as well
    MyFirebase.realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child("Data")
        .child(productName)
        .child(featureName)
        .remove();

    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child(productName)
        .once();

    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value != null) {
      Map<String, dynamic> variantsMap =
      Map<String, dynamic>.from(snapshot.value as Map);

      print("Before removal variantsMap: $variantsMap");

      variantsMap.updateAll((variantId, variantData) {
        final updatedData = Map<String, dynamic>.from(variantData);
        updatedData.remove(featureName); // Remove the feature from each variant
        return updatedData;
      });

      print("After removal variantsMap: $variantsMap");

      // Save the updated variants back to the database
      await realTimeDbRef
          .child(Constants.stringDbNodeInventory)
          .child(Constants.myUserId)
          .child(productName)
          .update(variantsMap);
    }
  }

  static Future<void> deleteTheSubFeatureFromAllTheVariants(String subFeature,
      String productName, String featureName) async {
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child(productName)
        .orderByChild(featureName)
        .equalTo(subFeature)
        .once();

    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      print(
          "MyFirebase deleteTheSubFeatureFromAllTheVariants ${snapshot.value}");
      Map<String, dynamic> variantsMap =
      Map<String, dynamic>.from(snapshot.value as Map);

      variantsMap.updateAll((variantId, variantData) {
        print(
            "My Firebase deleteTheSubFeatureFromAllTheVariants inside for each ");
        final updatedData = Map<String, dynamic>.from(variantData);
        updatedData[featureName] = "-";
        return updatedData;
      });

      realTimeDbRef
          .child(Constants.stringDbNodeInventory)
          .child(Constants.myUserId)
          .child(productName)
          .update(variantsMap);
    }
  }

  static Future<bool> checkForExistingOrders(String productName) async {
    print("MyFirebase checkForExisitng Orders product name is  ${productName}");
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child("MyOrders")
        .once();
    DataSnapshot snapshot = event.snapshot;
    print("MyFirebase checkForExistingOrders ${snapshot.value}");
    if (snapshot.value != null) {
      Map<dynamic, dynamic> sMap = snapshot.value as Map<dynamic, dynamic>;
      print("MyFirebase checkForExistingOrders entries ${sMap.entries}");
      for (var outerEntry in sMap.entries) {
        final innerMap = outerEntry.value as Map<dynamic, dynamic>;
        for (var innerKey in innerMap.keys) {
          if (innerKey == productName) {
            return true;
          }
          return false;
        }
      }
    } else {
      return false;
    }
    return false;
  }

  static Future<void> deleteTheProduct(String productName,
      String imageUrl) async {
//   delete the image if exists
    if (imageUrl.isNotEmpty && imageUrl != null) {
      var fileName = "${Constants.stringProductImages} ${productName.trim()}";

      Reference firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child('myTrade/productImages/${Constants.myUserId}/$fileName');

      await firebaseStorageRef.delete();
    }

    realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child("Data")
        .child(productName)
        .remove();

    realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child(productName)
        .remove();
  }

  static Future<void> deleteAllTheVariantsOfAProduct(String productName) async {
    realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child(productName)
        .remove();
  }

  static Future<Map<dynamic, dynamic>> getProductVariants(String productName,
      String userId) async {
    Map<dynamic, dynamic> variantsMap = {};
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(userId)
        .child(productName)
        .once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      variantsMap = snapshot.value as Map<dynamic, dynamic>;
      print("product variants are ${snapshot.value}");
      return variantsMap;
    }
    return variantsMap;
  }

  static Future<Map> getProductData(String? userId) async {
    Map map = {};
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(userId ?? "")
        .child("Data")
        .once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      print(" 225 ${snapshot.value}");
      map = snapshot.value as Map;
      map.keys.toList();
      print("map to keys ${map.keys.toList()}");
      map.forEach((key, value) {
        List l = [];
        l.add(key);
        print("the l is $l");
      });
    }

    return map;
  }

  static Future<void> getAllProducts(String distributorsUserId) async {
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(distributorsUserId)
        .once();
    DataSnapshot snapshot = event.snapshot;
    print("MyFirebase getAllProducts snapshotIs ${snapshot.value}");
  }

  static Future<bool> checkIfTheUserIsValidated(String phoneNumber) async {
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeValidatedNumbers)
        .child(phoneNumber)
        .once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      return true;
    } else {
      return false;
    }
  }

  static Future<void> updateProductImage(String productName,
      String productImageUrl) async {
    realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child("Data")
        .child(productName)
        .update({'imageUrl': productImageUrl});
  }

  static Future<void> setUserIdForProductCount() async {
    if (Constants.isDistributor) {
      print("MyFirebase setUserIdFor ${Constants.isDistributor}");
      await realTimeDbRef
          .child("ProductCount")
          .child(Constants.myUserId)
          .child("TotalProductCount")
          .set(10);
    } else {
      print("myFirebase productCount not set");
    }
  }

  static Future<bool> checkAvailableQuantityAndSetOrderAccordingly(
      String productName,
      String variantName,
      String distributorId,
      BuildContext context,
      int enteredProductQuantity) async {
    TransactionResult result;
    int availableProductQuantity;
    var qc = realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(distributorId)
        .child(productName)
        .child(variantName)
        .child('productQuantity')
        .ref;
    try {
      result = await qc.runTransaction((qc) {
        if (qc != null) {
          print(
              "MyFirebase checkAvailableQuantityAndSetOrderAccordingly qc is ${qc}");
          int qci = int.parse(qc.toString());
          print("MyFirebase qc i s${qci}");

          if (qci >= enteredProductQuantity) {
            int qcd = (qci ?? 0) - enteredProductQuantity;

            return Transaction.success(qcd);
          } else {
            Constants.showAToast(
                "EnteredQuantity Exceeds Available Quantity", context);
            return Transaction.abort();
          }
        } else {
          Constants.showAToast("The product is currently unavailable", context);
          return Transaction.abort();
        }
      });
    } catch (e) {
      return false;
    }

    if (result.committed) {
      return true;
    } else {
      return false;
    }
  }

  static Future<void> setMyOrder(String dsitributorsUserId,
      Map<dynamic, dynamic> variant, String productName) async {
    print("MyFirebase setMyOrder settingMyOrder");
    int previousOrderedQuantity = 0;
    int totalQuantity = 0;
    String variantName = variant.keys.first;
    String value = variant.values.first;

    print("myFirebase setMyOrder variantName is $variantName ");
    print("myFirebase setMyOrder value is $value ");
    print("myFirebase swtMyOrder totalQuantity $totalQuantity");

    DatabaseEvent quantityEvent = await realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(dsitributorsUserId)
        .child("MyOrders")
        .child(Constants.myUserId)
        .child(productName)
        .child(variantName)
        .child("orderedQuantity")
        .once();
    DataSnapshot quantitySnapshot = quantityEvent.snapshot;
    if (quantitySnapshot.value != null) {
      previousOrderedQuantity = int.parse("${quantitySnapshot.value}");
      totalQuantity = previousOrderedQuantity + int.parse(value);

      print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAA ${quantitySnapshot.value}");
    } else {
      print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA snapshot is null");
      totalQuantity = int.parse(value);
    }
    realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(dsitributorsUserId)
        .child("MyOrders")
        .child(Constants.myUserId)
        .child(productName)
        .child(variantName)
        .update({'orderedQuantity': totalQuantity, 'status': 'pending'});

    //   maintain order record for retailer
    realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child("OrdersPlaced")
        .child(dsitributorsUserId)
        .child(productName)
        .child(variantName)
        .update({'orderedQuantity': totalQuantity, 'status': 'pending'});
  }

  static Future<List<Map<dynamic, dynamic>>> getOrderVariants(
      String userId) async {
    List<Map<dynamic, dynamic>> productDetails = [];
    Map<dynamic, List<Map<dynamic, dynamic>>> myMap = {};
    String variantName = "";
    List<Future> futures = [];
    DatabaseEvent event;

    // Getting all the ordered variants
    if (Constants.isDistributor) {
      event = await realTimeDbRef
          .child(Constants.stringDbNodeInventory)
          .child(Constants.myUserId)
          .child("MyOrders")
          .child(userId)
          .once();
    } else {
      event = await realTimeDbRef
          .child(Constants.stringDbNodeInventory)
          .child(Constants.myUserId)
          .child("OrdersPlaced")
          .child(userId)
          .once();
    }

    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      print("MyFirebase getOrderVariants ${snapshot.value}");

      Map<dynamic, dynamic> pd = snapshot.value as Map<dynamic, dynamic>;

      // Grouping variants per product key
      pd.forEach((mKey, value) {
        value.forEach((key, val) {
          if (!myMap.containsKey(mKey)) {
            myMap[mKey] = [];
          }
          myMap[mKey]!.add({key: val});
        });
      });

      print("MyFirebase myMap $myMap");

      // Processing each variant entry
      myMap.forEach((productName, variantList) {
        for (var variantEntry in variantList) {
          futures.add(() async {
            String variantKey = variantEntry.keys.first;
            var variantData = variantEntry[variantKey];

            print("MyFirebase getOrderedVariants variant map is $variantEntry");
            print("MyFirebase getOrderVariants variant map keys $variantKey");

            DatabaseEvent event2;

            if (Constants.isDistributor) {
              event2 = await realTimeDbRef
                  .child(Constants.stringDbNodeInventory)
                  .child(Constants.myUserId)
                  .child(productName)
                  .child(variantKey)
                  .once();
            } else {
              event2 = await realTimeDbRef
                  .child(Constants.stringDbNodeInventory)
                  .child(userId)
                  .child(productName)
                  .child(variantKey)
                  .once();
            }

            DataSnapshot snapshot = event2.snapshot;
            if (snapshot.value != null) {
              print("MyFirebase getOrderVariants the variant is ${snapshot
                  .value}");
              Map<dynamic, dynamic> m = snapshot.value as Map;
              m.remove('productQuantity');

              m.addAll({
                'Ordered Quantity': variantData['orderedQuantity'],
                'Status': variantData['status'],
                'Product Name': productName,
                'Variant Name': variantKey,
              });

              print("MyFirebase orderedQuantity is $m");
              productDetails.add(m);
              print(
                  "MyFirebase getOrderVariants productDetails: $productDetails");
            }
          }());
        }
      });

      await Future.wait(futures);
    }

    print("MyFirebase getOrderVariants final product details: $productDetails");
    return productDetails;
  }


  static Future<List<UserProfile>> checkMyOrders() async {
    List<String> userIds = [];
    List<UserProfile> userProfiles = [];
    DatabaseEvent event;
    if (Constants.isDistributor) {
      event = await realTimeDbRef
          .child(Constants.stringDbNodeInventory)
          .child(Constants.myUserId)
          .child("MyOrders")
          .once();
    } else {
      event = await realTimeDbRef
          .child(Constants.stringDbNodeInventory)
          .child(Constants.myUserId)
          .child("OrdersPlaced")
          .once();
    }
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      print("MyFirebase checkMyOrders snapshot ${snapshot.value}");
      Map<dynamic, dynamic> orders = snapshot.value as Map<dynamic, dynamic>;
      orders.forEach((key, value) {
        userIds.add(key);
      });

      for (var userId in userIds) {
        DatabaseEvent event = await realTimeDbRef
            .child(Constants.stringDbNodeUsers)
            .child(userId)
            .once();
        DataSnapshot snapshot = event.snapshot;
        print("MyFirebase userID ss is ${snapshot.value}");
        if (snapshot.value != null) {
          final raw = snapshot.value as Map<Object?, Object?>;
          Map<String, dynamic> userProfile =
          raw.map((key, value) => MapEntry(key.toString(), value));
          print("MyFirebase checkMyOrders raw userProfile is ${userProfile}");
          userProfile.remove('MyFollowing');
          userProfiles.add(UserProfile.fromJson(userProfile));
          print(
              "MyuFirebase checkMyOrder added user is  ${userProfiles.first}");
        } else {
          print("snapshot is null");
        }
      }
    } else {
      print("MyFirebase checkMyOrders snapshot is null");
    }
    print("MyFirebase userProfiles list ${userProfiles}");
    return userProfiles;
  }

  static Future<void> updateProductQuantity(String productName,
      String variantName, String orderedQuantity) async {
    int orderedQ = int.parse(orderedQuantity);
    final pq = realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child(productName)
        .child(variantName)
        .child('productQuantity')
        .ref;
    pq.runTransaction((pq) {
      if (pq != null) {
        int currentQ = int.parse(pq.toString());
        int pqi = (currentQ as int ?? 0) + orderedQ;
        return Transaction.success(pqi);
      } else {
        return Transaction.abort();
      }
    });
  }

  static Future<void> updateOrderStatus(String retailersUserId,
      String productName, String variantName, String orderStatus) async {
    realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child("MyOrders")
        .child(retailersUserId)
        .child(productName)
        .child(variantName)
        .update({'status': orderStatus});

    realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(retailersUserId)
        .child("OrdersPlaced")
        .child(Constants.myUserId)
        .child(productName)
        .child(variantName)
        .update({'status': orderStatus});
  }

  static Future<String> checkIfOrderAccepted(String retailersUserId,
      String productName, String variantName) async {
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .child("OrdersPlaced")
        .child(retailersUserId)
        .child(productName)
        .child(variantName)
        .child("status")
        .once();

    DataSnapshot snapshot = event.snapshot;
    if (snapshot.exists) {
      if (snapshot.value == "pending") {
        return "pending";
      } else if (snapshot.value == "accepted") {
        return "accepted";
      } else {
        return "Nil";
      }
    } else {
      return "null";
    }
  }

  static getMyContactsFromDb() async {
    List<String> contacts =
    Constants.extractPhoneNumbers(await Constants.getAllContacts());

    for (String contact in contacts) {
      print("MyFirebase getMyContactsFromDb ${contact}");
      DatabaseEvent event = await realTimeDbRef
          .child(Constants.stringDbNodeValidatedNumbers)
          .once();
      DataSnapshot snapshot = event.snapshot;
      print("MyFirebase getMyContactsFromDb ${snapshot.value}");
    }
  }

  static Future<void> getVariantImage(String productName, String userId) async {
    print("getVariantImage the product name is ${productName}");
    if (Constants.productNameImageUrl.containsKey(productName)) {
      return Constants.productNameImageUrl[productName];
    } else {
      if (Constants.isDistributor) {
        DatabaseEvent event = await realTimeDbRef
            .child(Constants.stringDbNodeInventory)
            .child(Constants.myUserId)
            .child("Data")
            .child(productName)
            .child('imageUrl')
            .once();
        DataSnapshot snapshot = event.snapshot;
        print("MyFirebase getVariantImage  event is ${event}");
        print("getVariantImage ${snapshot.toString()}");
        print("getVariantImage ssssssssssvv ${snapshot.value}");
        if (snapshot.value != null) {
          var imageUrl = snapshot.value;
          Constants.productNameImageUrl.addAll({productName: imageUrl});
          print(
              "MyFirebase getVariantImage ${Constants.productNameImageUrl
                  .values}");
          return Constants.productNameImageUrl[productName];
        }
      } else {
        // userId will be of distributor
        DatabaseEvent event = await realTimeDbRef
            .child(Constants.stringDbNodeInventory)
            .child(userId)
            .child("Data")
            .child(productName)
            .child('imageUrl')
            .once();
        DataSnapshot snapshot = event.snapshot;
        if (snapshot.value != null) {
          var imageUrl = snapshot.value;
          Constants.productNameImageUrl.addAll({productName: imageUrl});
          print(
              "MyFirebase getVariantImage ${Constants.productNameImageUrl
                  .values}");
          return Constants.productNameImageUrl[productName];
        }
      }
    }
  }

  static saveMyManager(String managerMobileNumber, nameOfTheManager,
      String previousManagersPhoneNumber) {
    // remove previous managers phone number from validated numbers
    if (previousManagersPhoneNumber.isNotEmpty) {
      realTimeDbRef
          .child(Constants.stringDbNodeValidatedNumbers)
          .child(previousManagersPhoneNumber)
          .remove();
    }
    realTimeDbRef
        .child(Constants.stringDbNodeValidatedNumbers)
        .child(managerMobileNumber)
        .set({
      'name': nameOfTheManager,
      'isManager': true,
      'userIdOfMyDistributor': Constants.myUserId
    });

    //   save manager details in my profile
    realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .child("MyManager")
        .update({
      'phoneNumber': managerMobileNumber,
      'name': nameOfTheManager,
      'userIdOfMyDistributor': Constants.myUserId
    });
  }

  static Future<Map<dynamic, dynamic>> getMyManager() async {
    Map<dynamic, dynamic> managerMap = {};
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .child(Constants.stringDbNodeMyManager)
        .once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      print("MyFirebase getMyManager snapshot ${snapshot.value}");
      return managerMap = snapshot.value as Map<dynamic, dynamic>;
    } else {
      return managerMap;
    }
  }

  static deleteManager(String managerPhoneNUmber) {
    realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .child("MyManager")
        .remove();

    if (managerPhoneNUmber.isNotEmpty) {
      realTimeDbRef
          .child(Constants.stringDbNodeValidatedNumbers)
          .child(managerPhoneNUmber)
          .remove();
    }
  }

  static Future<List<UserProfile>> checkAndRemoveIfAlreadyFollowing(
      List<UserProfile> distributors) async {
    List<String> userIds = [];
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .child("MyFollowing")
        .once();
    DataSnapshot snapshot = event.snapshot;
    print(
        "MyFirebase checkAndRemoveIfAlreadyFollowing snapshot is ${snapshot
            .value}");
    if (snapshot.value != null) {
      Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
      userIds.addAll(map.keys.map((key) => key.toString()));
      print("the keys areb ${map.keys}");
      distributors
          .removeWhere((userProfile) => userIds.contains(userProfile.userId));
    }
    return distributors;
  }

  static checkFollowRequest() async {
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .child("MyFollowing")
        .once();
    DataSnapshot snapshot = event.snapshot;
    print("asasasas ${snapshot.value}");
  }

  static Future<String> getUserIdOfMyDistributor() async {
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeValidatedNumbers)
        .child(phoneNumber ?? "")
        .child("userIdOfMyDistributor")
        .once();

    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      print("MyFirebase gteUserIdOfMyDistributor ${snapshot.value}");
      return snapshot.value.toString();
    } else {
      return "";
    }
  }

  static deleteTheVariantWhoseAllTheFeaturesAreHyphen() {
    //   todo
  }

  static Future<Map<dynamic, dynamic>> getProductImages(
      List<String> productNames, String userId) async {
    // the user id will be of distributor if the user is a retailer and vice versa
    List<String> productImages = [];
    Map<dynamic, dynamic> productImageMap = {};
    String _userId;
    if (Constants.isDistributor) {
      _userId = Constants.myUserId;
    } else {
      _userId = userId;
    }
    for (var p in productNames) {
      DatabaseEvent event = await realTimeDbRef
          .child(
          Constants.stringDbNodeInventory)
          .child(_userId)
          .child('Data')
          .child(p)
          .child('imageUrl')
          .once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        productImages.add(snapshot.value as String);
        print("MyFirebase getProductImages ${productImages}");
        productImageMap.addAll({p: snapshot.value});
        print(
            "MyFirebase getProductImages productImageMap is ${productImageMap}");
      } else {
        print("MyFirebase getProductImages snapshot is null");
      }
    }
    return productImageMap;
  }

  static deleteOrder(String userId, String variantName, String productName) {
    // as per retialer
    realTimeDbRef
        .child(Constants.stringDbNodeInventory)
        .child(
        Constants.myUserId)
        .child("OrdersPlaced")
        .child(userId)
        .child(productName)
        .child(variantName)
        .remove();

    //   as per retailer in distributors id
    realTimeDbRef.child(Constants.stringDbNodeInventory).child(userId).child(
        "MyOrders").child(Constants.myUserId).child(productName).child(
        variantName).remove();
  }
}
