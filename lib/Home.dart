import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_trade/BLOC/DataState.dart';
import 'package:my_trade/Models/UserProfile.dart';
import 'package:my_trade/Utils/AppColors.dart';
import 'package:my_trade/BLOC/DataBloc.dart';
import 'package:my_trade/BLOC/DataEvent.dart';
import 'package:my_trade/Utils/Constants.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/MyNetwork.dart';
import 'package:my_trade/Utils/CustomCacheManager.dart';
import 'package:my_trade/main.dart';
import 'package:my_trade/showMyOrders.dart';
import 'package:my_trade/SideMenu.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

bool isLoading = true;
double _gResponsiveFontSize = 0.0;

class _HomeState extends State<Home> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initialSetUp();

    FirebaseDatabase.instance
        .ref(Constants.databaseRefStringMyTrade)
        .child(Constants.databaseRefStringEnv)
        .child(Constants.stringDbNodeInventory)
        .child(Constants.myUserId)
        .keepSynced(true);

    FirebaseDatabase.instance.ref(Constants.databaseRefStringMyTrade).child(Constants.databaseRefStringEnv)
        .child('ProductCount').child(Constants.myUserId).child('TotalProductCount').keepSynced(true);

  }

  initialSetUp() async {

    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //  Constants.requestContactsWithDialog(context);
    // })

    aboutUser.setBool("isManager", false);

    bool? isManager = aboutUser.getBool("isManager");
    if(isManager != null && isManager){
      Constants.isManager = true;
      Constants.myUserId = aboutUser.getString(Constants.sharedPrefStringDistributorsUserIdForManager ?? "")!;
      await MyFirebase.getMyProfileDetails(true);
    }else{
      await MyFirebase.getMyUserId();
      await MyFirebase.getMyProfileDetails(false);
      if(Constants.traderCreatedForTheFirstTime){
        Constants.traderCreatedForTheFirstTime = false;
        await MyFirebase.setUserIdForProductCount();

      }
    }


      context.read<DataBloc>().add(FetchData(Constants.blocStringGetOrders, Constants.myUserId));




    setState(() {
      isLoading = false;
    });
    print("home isDistributor ${Constants.isDistributor}");
  }

  // creating global key for drawer
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

  _gResponsiveFontSize = Constants.baseFontSize * (screenWidth / 375);

    return isLoading
        ? Scaffold(
            body: SafeArea(child: Constants.showSpinKit()),
          )
        : Scaffold(
            // enabling the drawer
            endDrawerEnableOpenDragGesture: true,
            // after enabling you have to define the key
            key: _drawerKey,
            // define/set the drawer
            drawer: Sidemenu(),
            appBar: AppBar(
              leading: IconButton(
                  onPressed: () {
                    //   open drawer from left to right
                    _drawerKey.currentState?.openDrawer();
                  },
                  icon: Icon(
                    Icons.menu,
                    color: AppColors.lightGray,
                  )),
              title: Text(
                Constants.stringNameOfTheBusiness ?? "My Shop",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightGray,
                    fontFamily: 'Roboto'),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      Constants.isDistributor
                          ? context
                              .read<DataBloc>()
                              .add(FetchData(Constants.blocStringGetAllRetailers, null))
                          : context
                              .read<DataBloc>()
                              .add(FetchData(Constants.blocStringGetAllDistributors, null));
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MyNetwork()));
                    },
                    icon: Icon(
                      Icons.account_box_outlined,
                      color: AppColors.lightGray,
                    ))
              ],
              centerTitle: true,
              backgroundColor: AppColors.steelBlue,
            ),

            body: SafeArea(
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.steelBlue,
                            ),
                            height: screenHeight * 0.25,
                            width: double.infinity,

                            child: Card(
                              shadowColor: AppColors.greyMedium.withOpacity(0.7),
                              margin: EdgeInsets.all(6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 10,
                              color: AppColors.steelBlue,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Text("Total Sales", style: TextStyle(color: AppColors.lightGray, fontWeight: FontWeight.bold, fontSize: 18),),
                                    SizedBox(height: 10,),
                                    Text("This Month So Far : 250000", style : TextStyle(color: AppColors.lightGray, fontWeight: FontWeight.bold, fontSize: 18)),
                                    SizedBox(height: 10,),
                                    Text("20% more than previous month", style : TextStyle(color: AppColors.lightGray, fontWeight: FontWeight.bold, fontSize: 18))
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 12,),
                    Expanded(
                      child: BlocBuilder<DataBloc, DataState>(builder: (context, state){
                        if(state.dataStatus == DataStatus.success && state.title == Constants.blocStringGetOrders){
                          return Orders(state.userProfiles!);

                        }else {
                          return Container(
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                      })
                    )
                  ],
                )
            ),
          );
  }

  Widget Orders(List<UserProfile>? up){
    print("Home Orders up is ${up}");
    bool dataIsNull = up!.isEmpty;
   return dataIsNull ?  Container(
      child: Center(child: Card(
        shadowColor: AppColors.greyMedium.withOpacity(0.7),
        margin: EdgeInsets.all(6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)
        ),
        elevation: 10,
        color: AppColors.greyMedium.withOpacity(0.4),
        child: Text("No Orders", style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold),),
      ),),
    ):
     Container(
      margin: EdgeInsets.all(8),
      child: Card(
        shadowColor: AppColors.greyMedium.withOpacity(0.7),
        margin: EdgeInsets.all(6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 10,
        color: AppColors.greyMedium.withOpacity(0.4),
        child:
        Column(
          children: [
            Text("Orders", style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold, fontSize: _gResponsiveFontSize),),
            SizedBox(height: 10,),
            Expanded(
              child: ListView.builder(
                  itemCount: up.length,
                  itemBuilder: (context, index){
                    return InkWell(
                      onTap: (){
                      
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ShowMyOrders(up[index].userId ?? "", up[index].nameOfTheShop ?? "")));
                      },
                      child: Container(
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.primary.withOpacity(0.7)
                      
                          ),
                          padding: EdgeInsets.all(10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child:
                                  up[index].profileImageUrl != null ?
                                  up[index].profileImageUrl!.isNotEmpty ?
                                  Image(height:80 ,width:80, image: CachedNetworkImageProvider(up[index].profileImageUrl!, cacheManager: CustomCacheManager()), fit: BoxFit.cover,)
                                      :
                                  Image.asset('assets/images/no_image.png', height: 80, width: 80,)
                                      :
                                  Image.asset('assets/images/no_image.png', height: 80, width: 80,)
                      
                              ),
                              SizedBox(width: 15,),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                      
                                  SizedBox(width: 15),
                                  Text(up[index].nameOfTheShop ?? "", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightGray, fontSize: 18),),
                                  SizedBox(height: 1.5,),
                                  Text(up[index].nameOfTheOwner ?? "", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.lightGray, fontSize: 18),),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(onPressed: (){
                                        up[index].phoneNumber != null ?
                                        up[index].phoneNumber!.isNotEmpty ?
                                        Constants.makePhoneCall(up[index].phoneNumber!)
                                            :Constants.showAToast("No Phone Number", context)
                                            :Constants.showAToast("No Phone Number", context);
                      
                                      }, icon: Icon(Icons.call, color: AppColors.charcoal,)),
                                      InkWell(
                                        onTap:(){
                                          up[index].phoneNumber != null ?
                                          up[index].phoneNumber!.isNotEmpty ?
                                          Constants.launchWhatsApp(up[index].phoneNumber!, "Hello")
                                              :Constants.showAToast("No Phone Number", context)
                                              :Constants.showAToast("No Phone Number", context);
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
                          )
                      ),
                    );
                  }),
            ),
          ],
        )
      ),
    );
  }
}
