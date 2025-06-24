

import 'package:my_trade/Models/UserProfile.dart';

enum DataStatus { initial, loading, success, failure }

class DataState{
  DataStatus dataStatus = DataStatus.loading;
  List<UserProfile>? userProfiles;
  UserProfile? userProfile;
  Map<dynamic, dynamic>? productDataMap;
  String? title;

  DataState({
    this.dataStatus = DataStatus.loading,
    this.userProfiles,
    this.userProfile,
    this.productDataMap,
    this.title
});

  DataState copyWith({
    final DataStatus? dataStatus,
    final List<UserProfile>? userProfiles,
    final UserProfile? userProfile,
    final Map<dynamic, dynamic>? productDataMap,
    final String? title
}){
    return DataState(
      dataStatus: dataStatus ?? this.dataStatus,
      userProfiles: userProfiles ?? this.userProfiles,
      userProfile: userProfile ?? this.userProfile,
      productDataMap: productDataMap ??this.productDataMap,
        title: title ?? this.title
    );
  }
}