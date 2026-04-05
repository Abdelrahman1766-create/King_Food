import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/address.dart';

class AddressProvider with ChangeNotifier {
  List<Address> _addresses = [];

  List<Address> get addresses => _addresses;

  AddressProvider() {
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final addressesJson = prefs.getStringList('addresses') ?? [];
    _addresses = addressesJson
        .map((json) => Address.fromJson(jsonDecode(json)))
        .toList();
    if (_addresses.isEmpty) {
      _addresses.addAll(demoAddresses);
    }
    notifyListeners();
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final addressesJson = _addresses
        .map((address) => jsonEncode(address.toJson()))
        .toList();
    await prefs.setStringList('addresses', addressesJson);
  }

  void addAddress(Address address) {
    _addresses.add(address);
    _saveAddresses();
    notifyListeners();
  }

  void removeAddress(String id) {
    _addresses.removeWhere((address) => address.id == id);
    _saveAddresses();
    notifyListeners();
  }

  void updateAddress(Address updatedAddress) {
    final index = _addresses.indexWhere(
      (address) => address.id == updatedAddress.id,
    );
    if (index != -1) {
      _addresses[index] = updatedAddress;
      _saveAddresses();
      notifyListeners();
    }
  }
}
