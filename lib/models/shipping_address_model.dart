import 'package:cloud_firestore/cloud_firestore.dart';

class ShippingAddressModel {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final bool isDefault;

  ShippingAddressModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.isDefault = false,
  });

  // Create a ShippingAddressModel from a Firestore document
  factory ShippingAddressModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ShippingAddressModel(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      addressLine1: data['addressLine1'] ?? '',
      addressLine2: data['addressLine2'],
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postalCode'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }

  // Create a ShippingAddressModel from a JSON map
  factory ShippingAddressModel.fromJson(Map<String, dynamic> json) {
    return ShippingAddressModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postalCode'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  // Convert ShippingAddressModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'isDefault': isDefault,
    };
  }

  // Format the address as a string
  String get formattedAddress {
    String address = '$addressLine1';
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      address += ', $addressLine2';
    }
    address += ', $city, $state $postalCode';
    return address;
  }

  // Create a copy of the address with updated fields
  ShippingAddressModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    bool? isDefault,
  }) {
    return ShippingAddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
