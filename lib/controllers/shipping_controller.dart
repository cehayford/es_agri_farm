import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shipping_address_model.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';

class ShippingController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ShippingAddressModel> _addresses = [];
  ShippingAddressModel? _selectedAddress;
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<ShippingAddressModel> get addresses => _addresses;
  ShippingAddressModel? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasAddresses => _addresses.isNotEmpty;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Fetch addresses for a user
  Future<void> fetchAddresses(String userId) async {
    _setLoading(true);
    _setError('');

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('shipping_addresses')
          .where('userId', isEqualTo: userId)
          .get();

      _addresses = snapshot.docs
          .map((doc) => ShippingAddressModel.fromSnapshot(doc))
          .toList();

      // Set selected address to default, or first one if no default
      if (_addresses.isNotEmpty) {
        final defaultAddress = _addresses.firstWhere(
          (address) => address.isDefault,
          orElse: () => _addresses.first,
        );
        _selectedAddress = defaultAddress;
      } else {
        _selectedAddress = null;
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch addresses: $e');
      _setLoading(false);
    }
  }

  // Add a new shipping address
  Future<bool> addAddress(ShippingAddressModel address) async {
    _setLoading(true);
    _setError('');

    try {
      // If this is the first address or marked as default, make sure no other address is default
      if (address.isDefault || _addresses.isEmpty) {
        // Update any existing default addresses to non-default
        for (var existingAddress in _addresses.where((a) => a.isDefault)) {
          await _firestore
              .collection('shipping_addresses')
              .doc(existingAddress.id)
              .update({'isDefault': false});
        }
      }

      // Create a new address document
      final docRef = _firestore.collection('shipping_addresses').doc();
      final newAddress = address.copyWith(
        id: docRef.id,
        isDefault: address.isDefault || _addresses.isEmpty, // First address is default
      );

      await docRef.set(newAddress.toJson());

      // Refresh the address list
      await fetchAddresses(address.userId);

      // Set as selected address if it's default or first address
      if (newAddress.isDefault || _addresses.length == 1) {
        _selectedAddress = newAddress;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add address: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update an existing shipping address
  Future<bool> updateAddress(ShippingAddressModel address) async {
    _setLoading(true);
    _setError('');

    try {
      // If this address is being set as default, update other addresses
      if (address.isDefault) {
        // Update any existing default addresses to non-default
        for (var existingAddress in _addresses.where((a) => a.isDefault && a.id != address.id)) {
          await _firestore
              .collection('shipping_addresses')
              .doc(existingAddress.id)
              .update({'isDefault': false});
        }
      }

      // Update the address
      await _firestore
          .collection('shipping_addresses')
          .doc(address.id)
          .update(address.toJson());

      // Refresh the address list
      await fetchAddresses(address.userId);

      // Update selected address if needed
      if (address.isDefault || (_selectedAddress != null && _selectedAddress!.id == address.id)) {
        _selectedAddress = _addresses.firstWhere((a) => a.id == address.id);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update address: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete a shipping address
  Future<bool> deleteAddress(String addressId, String userId) async {
    _setLoading(true);
    _setError('');

    try {
      // Get the address to check if it's default
      final address = _addresses.firstWhere((a) => a.id == addressId);
      final wasDefault = address.isDefault;

      // Delete the address
      await _firestore.collection('shipping_addresses').doc(addressId).delete();

      // Refresh the address list
      await fetchAddresses(userId);

      // If we deleted the default address and there are other addresses,
      // make the first one the default
      if (wasDefault && _addresses.isNotEmpty) {
        final newDefault = _addresses.first;
        await _firestore
            .collection('shipping_addresses')
            .doc(newDefault.id)
            .update({'isDefault': true});

        // Refresh again to get updated default status
        await fetchAddresses(userId);
      }

      // Update selected address
      if (_addresses.isNotEmpty) {
        _selectedAddress = _addresses.firstWhere(
          (address) => address.isDefault,
          orElse: () => _addresses.first,
        );
      } else {
        _selectedAddress = null;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete address: $e');
      _setLoading(false);
      return false;
    }
  }

  // Set selected address
  void selectAddress(String addressId) {
    _selectedAddress = _addresses.firstWhere((a) => a.id == addressId);
    notifyListeners();
  }
}
