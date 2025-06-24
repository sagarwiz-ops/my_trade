import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
    final uc = realTimeDbRef.child("TotalUserCount").child("UserCount").ref;

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
    realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .update({'profileImageUrl': imageUrl});
  }

  static Future<void> uploadImageWithAUniqueNumber() async {
    final pc = realTimeDbRef
        .child("ProductCount")
        .child(Constants.myUserId)
        .child("TotalProductCount")
        .ref;
    String productNumber;

    pc.runTransaction((pc) {
      if (pc != null) {
        Constants.stringProductNumberForImage = pc.toString();
        print(
            "product number for uplaoding image to firebase is ${Constants.stringProductNumberForImage}");
        int pci = (pc as int ?? 0) + 1;
        return Transaction.success(pci);
      } else {
        productNumber = "";
        return Transaction.abort();
      }
    });
  }

  static getMyUserId() async {
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

  static getMyProfileDetails() async {
    DatabaseEvent event = await realTimeDbRef
        .child(Constants.stringDbNodeUsers)
        .child(Constants.myUserId)
        .once();
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      print("myProfile ${snapshot.value}");
      Constants.isDistributor = data["profileType"] == "Distributor";
      print(
          "MyFirebase getMyProfileDetails isDistributor ${Constants.isDistributor} ");
      Constants.stringNameOfTheBusiness = data["nameOfTheShop"];
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
        "MyFirebase checkMyFollowRequests follow Requests are ${snapshot.value}");
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
            "MyFirebase getAllRetailersFollowRequests snapshot.value ${snapshot.value} ");
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
        final raw = snapshot.value as Map<Object?, Object?>;
        Map<String, dynamic> map =
            raw.map((key, value) => MapEntry(key.toString(), value));

        print("MyFirebase getMyFollowers bbbbb ${map}");
        userProfiles.add(UserProfile.fromJson(map));
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
      final raw = snapshot.value as Map<Object?, Object?>;
      Map<String, dynamic> map =
          raw.map((key, value) => MapEntry(key.toString(), value));

      print("MyFirebase getMyFollowers bbbbb ${map}");
      userProfiles.add(UserProfile.fromJson(map));
    }
    print(
        "MyFirebase getMyFollowers myUserProfiles ${userProfiles.first.nameOfTheShop}");
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

  static saveInventory(
      String productName,
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
          ..remove("productQuantity")
          ..remove("productPrice");

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

  static saveProduct(String productName, Map<String, dynamic> lists,
      String productImageUrl) async {
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

  static updateAllTheVariantsWithTheNewFeature(
      String productName, List<String> featureNames) async {
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

  static Future<void> removeFeatureFromAllVariants(
      String productName, String featureName) async {
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

  static Future<void> deleteTheSubFeatureFromAllTheVariants(
      String subFeature, String productName, String featureName) async {
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

  static Future<void> deleteTheProduct(String productName) async {
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

  static Future<Map<dynamic, dynamic>> getProductVariants(
      String productName, String userId) async {
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

  static getAllProducts(String distributorsUserId) async {
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

  static Future<void> updateProductImage(
      String productName, String productImageUrl) async {
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
      realTimeDbRef
          .child("ProductCount")
          .child(Constants.myUserId)
          .child("TotalProductCount")
          .set(10);
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
        return Transaction.abort();
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
    Map<dynamic, dynamic> myMap = {};
    String variantName = "";
    List<Future> futures = [];
    DatabaseEvent event;
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
      pd.forEach((mKey, value) {
        value.forEach((key, value) {
          myMap.addAll({
            mKey: {key: value}
          });
        });
      });
      print("MyFirebase myMap ${myMap}");
      myMap.forEach((key, value) async {
        // key will be the product name
        futures.add(() async {
          Map<dynamic, dynamic> variantMap = value as Map<dynamic, dynamic>;
          print(
              "MyFirebase getOrderVariants variant map keys  ${variantMap.keys.first}");
          variantName = variantMap.keys.first;
          print("MyFirebase aaaaa ${variantName}");
          DatabaseEvent event2;
          if (Constants.isDistributor) {
            event2 = await realTimeDbRef
                .child(Constants.stringDbNodeInventory)
                .child(Constants.myUserId)
                .child(key)
                .child(variantMap.keys.first)
                .once();
          } else {
            event2 = await realTimeDbRef
                .child(Constants.stringDbNodeInventory)
                // this is distributors userId
                .child(userId)
                .child(key)
                .child(variantMap.keys.first)
                .once();
          }
          DataSnapshot snapshot = event2.snapshot;
          if (snapshot.value != null) {
            print(
                "MyFirebase getOrderVariants the variant is ${snapshot.value}");
            Map<dynamic, dynamic> m = snapshot.value as Map;
            // remove product quantity
            m.remove('productQuantity');
            m.addAll({
              'Ordered Quantity': variantMap.values.first['orderedQuantity'],
              'Product Name': key,
              'Variant Name': variantMap.keys.first
            });
            print("MyFirebase orderedQuantity is ${m}");
            productDetails.add(m);

            print(
                "MyFirebase getOrderVariants final product detials are  ${productDetails}");
          }
        }());
      });
      await Future.wait(futures);
    }
    print(
        "MyFirebase getOrderVariants final product details are  ${productDetails}");

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
        final raw = snapshot.value as Map<Object?, Object?>;
        Map<String, dynamic> userProfile =
            raw.map((key, value) => MapEntry(key.toString(), value));
        print("MyFirebase checkMyOrders raw userProfile is ${userProfile}");
        userProfile.remove('MyFollowing');
        userProfiles.add(UserProfile.fromJson(userProfile));
        print("MyuFirebase checkMyOrder added user is  ${userProfiles.first}");
      }
    } else {
      print("MyFirebase checkMyOrders snapshot is null");
    }
    print("MyFirebase userProfiles list ${userProfiles}");
    return userProfiles;
  }

  static Future<void> updateProductQuantity(
      String productName, String variantName, String orderedQuantity) async {
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

  static Future<String> checkIfOrderAccepted(
      String retailersUserId, String productName, String variantName) async {
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

  static Future<String> getVariantImage(
      String productName, String userId) async {
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
        var imageUrl = snapshot.value;
        Constants.productNameImageUrl.addAll({productName: imageUrl});
        print(
            "MyFirebase getVariantImage ${Constants.productNameImageUrl.values}");
        return Constants.productNameImageUrl[productName];
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
        var imageUrl = snapshot.value;
        Constants.productNameImageUrl.addAll({productName: imageUrl});
        print(
            "MyFirebase getVariantImage ${Constants.productNameImageUrl.values}");
        return Constants.productNameImageUrl[productName];
      }
    }
  }
}
