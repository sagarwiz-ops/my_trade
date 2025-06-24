


import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_trade/BLOC/DataEvent.dart';
import 'package:my_trade/BLOC/DataState.dart';
import 'package:my_trade/Firebase/MyFirebase.dart';
import 'package:my_trade/Models/UserProfile.dart';
import 'package:my_trade/Utils/Constants.dart';

class DataBloc extends Bloc<DataEvent, DataState>{
  DataBloc():super(DataState()){
    on<FetchData>(fetchData);
  }

  Future<FutureOr<void>> fetchData(FetchData event, Emitter<DataState> emit) async{
    emit(state.copyWith(dataStatus: DataStatus.loading));

    if(event.parameter == Constants.blocStringGetAllDistributors){
      List<UserProfile> allDistributors = await MyFirebase.getAllDistributors();
      emit(state.copyWith(dataStatus: DataStatus.success, userProfiles:allDistributors, title: Constants.blocStringGetAllDistributors));
    }else if(event.parameter == Constants.blocStringGetAllRetailers){
      List<UserProfile> allRetailers = await MyFirebase.getAllRetailersFollowRequests();
      emit(state.copyWith(dataStatus: DataStatus.success, userProfiles:allRetailers, title: Constants.blocStringGetAllRetailers));
    }

    else if(event.parameter == Constants.blocStringGetMyProducts){
     Map map = await  MyFirebase.getProductData(event.userId);
      emit(state.copyWith(dataStatus: DataStatus.success, productDataMap: map, title: Constants.blocStringGetMyProducts));
    }else if(event.parameter == Constants.blocStringGetOrders){
      List<UserProfile> up = await MyFirebase.checkMyOrders();
      print("DataBloc up is ${up}");
      emit(state.copyWith(dataStatus: DataStatus.success, userProfiles: up, title: Constants.blocStringGetOrders));
    }else if(event.parameter == Constants.blocStringGetMyProfileData){
      UserProfile? userProfile = await MyFirebase.getMyProfileData();
      emit(state.copyWith(dataStatus: DataStatus.success, userProfile: userProfile, title: Constants.blocStringGetMyProfileData));


    }


  }

}