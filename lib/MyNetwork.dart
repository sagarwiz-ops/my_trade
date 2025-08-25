import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_trade/ShowProducts.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/BLOC/DataBloc.dart';
import 'package:my_trade/BLOC/DataEvent.dart';
import 'package:my_trade/BLOC/DataState.dart';
import 'package:my_trade/Utils/Constants.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Models/UserProfile.dart';
import 'package:my_trade/Utils/CustomCacheManager.dart';

class MyNetwork extends StatefulWidget {
  const MyNetwork({super.key});

  @override
  State<MyNetwork> createState() => _MyNetworkState();
}

class _MyNetworkState extends State<MyNetwork> {
  bool followersReceived = false;
  bool distributorsReceived = false;
  List<UserProfile> followersList = [];
  List<UserProfile> myDistributors = [];
  List<String> searchListRetailers = [];
  List<String> searchListDistributors = [];
  List<UserProfile> filteredItems = [];
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  String followStatus = "Follow";

  @override
  initState() {
    // TODO: implement initState
    super.initState();
    print("${Constants.isDistributor}");
    _initialize();
  }

  _initialize() async {
    if (Constants.isDistributor) {
      // getting all the followers/retailers of a distributor
      followersList = await MyFirebase.getMyFollowers();
      for (var f in followersList) {
        searchListRetailers.add(f.nameOfTheShop ?? "");
      }
      print(
          "showDistributors _initialize followersList ${followersList.first.profileImageUrl!.isEmpty}");
    } else {
      myDistributors = await MyFirebase.getMyDistributors();
      for (var d in myDistributors) {
        searchListDistributors.add(d.nameOfTheShop ?? "");
      }

      print(
          "showDistributors _initialize distributorsList ${myDistributors.length}");
    }

    if (followersList.isNotEmpty) {
      setState(() {
        followersReceived = true;
      });
    }

    if (myDistributors.isNotEmpty) {
      setState(() {
        distributorsReceived = true;
      });
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void stopSearch() {
    setState(() {
      _searchController.text = "";
      _isSearching = false;
    });
  }

  _filterList(String query) {
    if (query.isNotEmpty) {
      if (Constants.isDistributor) {
        setState(() {
          filteredItems = followersList
              .where((retailer) => retailer.nameOfTheShop!
                  .toLowerCase()
                  .contains(query.toLowerCase()))
              .toList();
        });
      } else {
        setState(() {
          filteredItems = myDistributors
              .where((retailer) => retailer.nameOfTheShop!
                  .toLowerCase()
                  .contains(query.toLowerCase()))
              .toList();
        });
      }
    } else {
      setState(() {
        filteredItems = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              context.read<DataBloc>().add(
                  FetchData(Constants.blocStringGetOrders, Constants.myUserId));
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppColors.white,
            )),
        title: _isSearching
            ? TextField(
                style: TextStyle(color: AppColors.lightGray),
                cursorColor: AppColors.lightGray,
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                    label: Text(
                  "Search",
                  style: TextStyle(color: AppColors.lightGray),
                )),
                onChanged: _filterList,
              )
            : Text(
                "My Network",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.lightGray),
              ),
        backgroundColor: AppColors.steelBlue,
        centerTitle: true,
        actions: [
          _isSearching
              ? IconButton(
                  onPressed: () {
                    stopSearch();
                  },
                  icon: Icon(
                    Icons.cancel_outlined,
                    color: AppColors.lightGray,
                  ))
              : IconButton(
                  onPressed: () {
                    _startSearch();
                  },
                  icon: Icon(
                    Icons.search,
                    color: AppColors.lightGray,
                  ))
        ],
      ),
      body: SafeArea(child: Container(
        child: BlocBuilder<DataBloc, DataState>(builder: (context, state) {
          if (state.dataStatus == DataStatus.success &&
              (state.title == Constants.blocStringGetAllDistributors ||
                  state.title == Constants.blocStringGetAllRetailers)) {
            var l = state.userProfiles;
            return Constants.isDistributor
                ? showRetailers(l)
                : showDistributors(l);
          } else {
            return Container();
          }
        }),
      )),
    );
  }

  Widget showDistributors(List<UserProfile>? userProfiles) {

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: [
        if (!_isSearching)
          (userProfiles == null || userProfiles.isEmpty)
              ? Container(
                  height: screenHeight * 0.35,
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.greyMedium, width: 2)),
                  margin: EdgeInsets.all(10),
                  child: Center(
                    child: Text("No Data"),
                  ),
                )
              : Container(
                  margin: EdgeInsets.all(10),
                  height: screenHeight * 0.35,
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.greyMedium, width: 2)),
                  child: ListView.builder(
                      itemCount: userProfiles.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.steelBlue.withOpacity(0.8),
                            ),
                            margin: EdgeInsets.all(10),
                            padding: EdgeInsets.all(8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: userProfiles[index].profileImageUrl !=
                                            null
                                        ? userProfiles[index]
                                                .profileImageUrl!
                                                .isNotEmpty
                                            ? CachedNetworkImage(
                                                height: 60,
                                                width: 60,
                                                imageUrl: userProfiles[index]
                                                    .profileImageUrl!,
                                                cacheManager:
                                                    CustomCacheManager(),
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                      fit: BoxFit.cover,
                                                height: 60,
                                                width: 60,
                                                'assets/images/no_image.png')
                                        : Image.asset(
                                        fit: BoxFit.cover,
                                            height: 60,
                                            width: 60,
                                            'assets/images/no_image.png')),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userProfiles[index].nameOfTheShop ?? "",
                                        style: TextStyle(
                                            color: AppColors.lightGray,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Text(
                                        userProfiles[index].nameOfTheOwner ??
                                            "",
                                        style: TextStyle(
                                            color: AppColors.lightGray,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      )
                                    ]),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                        onPressed: () async {
                                          Constants.showAToast(
                                              "Request sent", context);
                                          await MyFirebase.setFollowRequest(
                                              userProfiles[index]
                                                  .userId
                                                  .toString());

                                          if(followStatus == "Follow"){
                                            setState(() {
                                              followStatus = "Requested";
                                            });
                                          }
                                        },
                                        child: Text(followStatus, style: TextStyle(color: AppColors.lightGray),))
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                ),
        SizedBox(
          height: 10,
        ),
        !distributorsReceived
            ? SingleChildScrollView(
              child: Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.greyMedium, width: 2)),
                  child: Container(
                    child: Text("No Distributors"),
                  ),
                ),
            )
            : Container(
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border:
                        Border.all(color: AppColors.greyMedium, width: 2)),
                child: ListView.builder(
                    itemCount: myDistributors.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ShowProducts(
                                      myDistributors[index].nameOfTheShop ??
                                          "",
                                      myDistributors[index].userId ?? "")));
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.steelBlue.withOpacity(0.8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              myDistributors[index].profileImageUrl != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                      child: myDistributors[index]
                                              .profileImageUrl!
                                              .isEmpty
                                          ? Image.asset(
                                              fit: BoxFit.cover,
                                              width: 50,
                                              height: 50,
                                              'assets/images/no_image.png')
                                          : CachedNetworkImage(
                                              height: 60,
                                              width: 60,
                                              imageUrl:
                                                  myDistributors[index]
                                                      .profileImageUrl!,
                                              cacheManager:
                                                  CustomCacheManager(),
                                              fit: BoxFit.cover,
                                            ),
                                    )
                                  :
                                  // if profile image is null
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                          fit: BoxFit.cover,
                                          width: 50,
                                          height: 50,
                                          'assets/images/no_image.png'),
                                    ),
                              SizedBox(
                                width: 15,
                              ),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    myDistributors[index].nameOfTheShop ??
                                        "",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightGray,
                                        fontSize: 16),
                                  ),
                                  Text(
                                      myDistributors[index]
                                              .nameOfTheOwner ??
                                          "",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.lightGray,
                                          fontSize: 14)),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                          onPressed: () {
                                            _isSearching
                                                ? filteredItems[index]
                                                            .phoneNumber !=
                                                        null
                                                    ? filteredItems[index]
                                                            .phoneNumber!
                                                            .isNotEmpty
                                                        ? Constants.makePhoneCall(filteredItems[index]
                                                            .phoneNumber!)
                                                        : Constants.showAToast(
                                                            "No Phone Number",
                                                            context)
                                                    : Constants.showAToast(
                                                        "No Phone Number",
                                                        context)
                                                : myDistributors[index]
                                                            .phoneNumber !=
                                                        null
                                                    ? myDistributors[index]
                                                            .phoneNumber!
                                                            .isNotEmpty
                                                        ? Constants.makePhoneCall(
                                                            myDistributors[index]
                                                                .phoneNumber!)
                                                        : Constants.showAToast(
                                                            "No Phone Number",
                                                            context)
                                                    : Constants.showAToast(
                                                        "No Phone Number",
                                                        context);
                                          },
                                          icon: Icon(
                                            Icons.call,
                                            color: AppColors.charcoal,
                                          )),
                                      InkWell(
                                        onTap: () {
                                          _isSearching
                                              ? filteredItems[index]
                                                          .phoneNumber !=
                                                      null
                                                  ? filteredItems[index]
                                                          .phoneNumber!
                                                          .isNotEmpty
                                                      ? Constants.launchWhatsApp(
                                                          filteredItems[index]
                                                              .phoneNumber!,
                                                          "Hello")
                                                      : Constants.showAToast(
                                                          "No Phone Number",
                                                          context)
                                                  : Constants.showAToast(
                                                      "No Phone Number",
                                                      context)
                                              : myDistributors[index]
                                                          .phoneNumber !=
                                                      null
                                                  ? myDistributors[index]
                                                          .phoneNumber!
                                                          .isNotEmpty
                                                      ? Constants.launchWhatsApp(
                                                          myDistributors[index]
                                                              .phoneNumber!,
                                                          "Hello")
                                                      : Constants.showAToast(
                                                          "No Phone Number",
                                                          context)
                                                  : Constants.showAToast(
                                                      "No Phone Number",
                                                      context);
                                        },
                                        child: FaIcon(
                                          FontAwesomeIcons.whatsapp,
                                          color: AppColors.whatsAppGreen,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ))
                            ],
                          ),
                        ),
                      );
                    }),
              )
      ],
    );
  }

  Widget showRetailers(List<UserProfile>? userProfiles) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: [
        if (!_isSearching)
          (userProfiles == null || userProfiles.isEmpty)
              ? Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.greyMedium, width: 2)),
                  height: screenHeight * 0.35,
                  child: Center(child: Text("No Requests")))
              : Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.greyMedium, width: 2)),
                  height: screenHeight * 0.35,
                  child: ListView.builder(
                      itemCount: userProfiles.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.steelBlue.withOpacity(0.7),
                          ),
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                child: userProfiles[index].profileImageUrl != null
                          ? userProfiles[index].profileImageUrl!.isNotEmpty ?
                                    Image.network(userProfiles[index].profileImageUrl!, height: 70, width: 70, fit: BoxFit.cover,)
                                :
                                Image.asset(
                                    height: 70,
                                    width: 70,
                                    'assets/images/no_image.png')
                                    :
                        Image.asset(
                        height: 70,
                        width: 70,
                        'assets/images/no_image.png')


                              ),
                              SizedBox(
                                width: 25,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      userProfiles[index]
                                          .nameOfTheShop
                                          .toString(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, color: AppColors.lightGray),
                                    ),
                                    SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      userProfiles[index]
                                          .nameOfTheOwner
                                          .toString(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, color: AppColors.lightGray),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                            onPressed: () async {
                                              Constants.showAToast(
                                                  "Request sent", context);
                                              await MyFirebase
                                                  .acceptFollowRequest(
                                                      userProfiles[index]
                                                          .userId
                                                          .toString());
                                              await MyFirebase
                                                  .removeFollowRequestAfterAccepting(
                                                      userProfiles[index]
                                                          .userId
                                                          .toString());
                                              setState(() {
                                                userProfiles.removeAt(index);
                                              });
                                            },
                                            child: InkWell(
                                              onTap: () {

                                              },
                                              child: Text(
                                                "Accept",
                                                style: TextStyle(
                                                  color: AppColors.lightGray,
                                                ),
                                              ),
                                            ))
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                ),
        // SizedBox(
        //   height: 8,
        // ),
        followersReceived
            ? SingleChildScrollView(
              child: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.greyMedium, width: 2)),
                  child: ListView.builder(
                      itemCount: _isSearching
                          ? filteredItems.length
                          : followersList.length,
                      itemBuilder: (context, index) {
                        return Container(
                          padding: EdgeInsets.all(8),
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.steelBlue.withOpacity(0.85),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              !_isSearching
                                  ? followersList[index].profileImageUrl !=
                                          null
                                      ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                          child: followersList[index]
                                                  .profileImageUrl!
                                                  .isEmpty
                                              ? Image.asset(
                                                  fit: BoxFit.cover,
                                                  width: 60,
                                                  height: 60,
                                                  'assets/images/no_image.png')
                                              : Image.network(
                                                  fit: BoxFit.cover,
                                                  width: 60,
                                                  height: 60,
                                                  followersList[index]
                                                      .profileImageUrl!),
                                        )
                                      :
                                      // if profile image is null
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                          child: Image.asset(
                                              fit: BoxFit.cover,
                                              width: 60,
                                              height: 60,
                                              'assets/images/no_image.png'),
                                        )
                                  : filteredItems[index].profileImageUrl !=
                                          null
                                      ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                          child: filteredItems[index]
                                                  .profileImageUrl!
                                                  .isEmpty
                                              ? Image.asset(
                                                  fit: BoxFit.cover,
                                                  width: 60,
                                                  height: 60,
                                                  'assets/images/no_image.png')
                                              : Image.network(
                                                  fit: BoxFit.cover,
                                                  width: 60,
                                                  height: 60,
                                                  filteredItems[index]
                                                      .profileImageUrl!),
                                        )
                                      :
                                      // if profile image is null
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                          child: Image.asset(
                                              fit: BoxFit.cover,
                                              width: 60,
                                              height: 60,
                                              'assets/images/no_image.png'),
                                        ),
                              SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isSearching
                                        ? filteredItems[index]
                                                .nameOfTheShop ??
                                            ""
                                        : followersList[index]
                                                .nameOfTheShop ??
                                            "",
                                    style: TextStyle(
                                        color: AppColors.lightGray,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  Text(
                                    _isSearching
                                        ? filteredItems[index]
                                                .nameOfTheOwner ??
                                            ""
                                        : followersList[index]
                                                .nameOfTheOwner ??
                                            "",
                                    style: TextStyle(
                                        color: AppColors.lightGray,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                          onPressed: () {
                                            _isSearching
                                                ? filteredItems[index]
                                                            .phoneNumber !=
                                                        null
                                                    ? filteredItems[index]
                                                            .phoneNumber!
                                                            .isNotEmpty
                                                        ? Constants.makePhoneCall(
                                                            filteredItems[index]
                                                                .phoneNumber!)
                                                        : Constants.showAToast(
                                                            "No Phone Number",
                                                            context)
                                                    : Constants.showAToast(
                                                        "No Phone Number", context)
                                                : followersList[index]
                                                            .phoneNumber !=
                                                        null
                                                    ? followersList[index]
                                                            .phoneNumber!
                                                            .isNotEmpty
                                                        ? Constants.makePhoneCall(
                                                            followersList[index]
                                                                .phoneNumber!)
                                                        : Constants.showAToast(
                                                            "No Phone Number",
                                                            context)
                                                    : Constants.showAToast(
                                                        "No Phone Number",
                                                        context);
                                          },
                                          icon: Icon(
                                            Icons.call,
                                            color: AppColors.charcoal,
                                          )),
                                      InkWell(
                                        onTap: () {
                                          _isSearching
                                              ? filteredItems[index]
                                                          .phoneNumber !=
                                                      null
                                                  ? filteredItems[index]
                                                          .phoneNumber!
                                                          .isNotEmpty
                                                      ? Constants.launchWhatsApp(
                                                          filteredItems[index]
                                                              .phoneNumber!,
                                                          "Hello")
                                                      : Constants.showAToast(
                                                          "No Phone Number",
                                                          context)
                                                  : Constants.showAToast(
                                                      "No Phone Number",
                                                      context)
                                              : followersList[index]
                                                          .phoneNumber !=
                                                      null
                                                  ? followersList[index]
                                                          .phoneNumber!
                                                          .isNotEmpty
                                                      ? Constants.launchWhatsApp(
                                                          followersList[index]
                                                              .phoneNumber!,
                                                          "Hello")
                                                      : Constants.showAToast(
                                                          "No Phone Number",
                                                          context)
                                                  : Constants.showAToast(
                                                      "No Phone Number",
                                                      context);
                                        },
                                        child: FaIcon(
                                          FontAwesomeIcons.whatsapp,
                                          color: AppColors.whatsAppGreen,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ))
                            ],
                          ),
                        );
                      })),
            )
            : Container(
                child: Center(
                  child: Text("No Followers"),
                ),
              )
      ],
    );
  }
}
