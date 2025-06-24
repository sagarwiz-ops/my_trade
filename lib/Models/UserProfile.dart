import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';

part 'UserProfile.g.dart';


@JsonSerializable()
class UserProfile {
  final String? nameOfTheShop;
  final String? nameOfTheOwner;
  final String? profileType;
  final String? profileImageUrl;
  final String? userId;
  final String? phoneNumber;

  UserProfile({
    required this.nameOfTheOwner,
    required this.nameOfTheShop,
    required this.profileType,
     required this.profileImageUrl,
     required this.userId,
    required this.phoneNumber
  });

  UserProfile copyWith({
    final String? nameOfTheShop,
    final String? nameOfTheOwner,
    final String? profileType,
    final String? profileImageUrl,
    final String? userId,
    final String? phoneNumber
  }){
    return
      UserProfile
        (
          nameOfTheOwner: nameOfTheOwner ?? this.nameOfTheOwner,
          nameOfTheShop: nameOfTheShop ?? this.nameOfTheShop,
          profileType: profileType ?? this.profileType,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        userId: userId ?? this.userId,
        phoneNumber: phoneNumber ?? this.phoneNumber

      );
  }

  Map<String, dynamic> toMap(){
  return{
  'nameOfTheShop': nameOfTheShop,
  'nameOfTheOwner': nameOfTheOwner,
  'profileType': profileType,
    'profileImageUrl': profileImageUrl,
    'userId' :userId
  };

  }

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}