import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class MyOrders {
  final int? productQuantity;
  final String? variantName;

  MyOrders({required this.productQuantity, required this.variantName});

  MyOrders copyWith({
    final int? productQuantity,
    final String? variantName,
  }) {
    return MyOrders(
        productQuantity: productQuantity ?? this.productQuantity,
        variantName: variantName ?? this.variantName);
  }
}
