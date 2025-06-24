// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserProfile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      nameOfTheOwner: json['nameOfTheOwner'] as String?,
      nameOfTheShop: json['nameOfTheShop'] as String?,
      profileType: json['profileType'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      userId: json['userId'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'nameOfTheShop': instance.nameOfTheShop,
      'nameOfTheOwner': instance.nameOfTheOwner,
      'profileType': instance.profileType,
      'profileImageUrl': instance.profileImageUrl,
      'userId': instance.userId,
      'phoneNumber': instance.phoneNumber,
    };
