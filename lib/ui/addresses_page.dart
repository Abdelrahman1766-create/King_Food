import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/address.dart';
import '../providers/address_provider.dart';
import '../services/location_service.dart';
import 'gis_map_picker.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key, this.selected});
  final Address? selected;

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  Address? _current;
  bool _didInitCurrent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitCurrent) {
      final addresses = context.read<AddressProvider>().addresses;
      _current = widget.selected ??
          (addresses.isNotEmpty ? addresses.first : null);
      _didInitCurrent = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressProvider>(
      builder: (context, addressProvider, child) {
        final addresses = addressProvider.addresses;
        if (_current == null && addresses.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _current = addresses.first);
            }
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Addresses')),
          body: ListView(
            children: [
              ...addresses.map(
                (a) => ListTile(
                  leading: Radio<Address>(
                    value: a,
                    groupValue: _current,
                    onChanged: (val) => setState(() => _current = val),
                  ),
                  title: Text(a.label),
                  subtitle: Text('${a.line1}, ${a.city}\n${a.phone}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () =>
                        _confirmDeleteAddress(context, a, addressProvider),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_location_alt_outlined),
                title: const Text('Add new address'),
                onTap: () => _showAddAddressDialog(context, addressProvider, (
                  newAddress,
                ) {
                  setState(() => _current = newAddress);
                }),
              ),
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('Add address from map'),
                subtitle: const Text('Choose location on map'),
                onTap: () => _showMapAddressDialog(context, addressProvider, (
                  newAddress,
                ) {
                  setState(() => _current = newAddress);
                }),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _current == null
                    ? null
                    : () {
                        Navigator.of(context).pop<Address>(_current);
                      },
                child: const Text('Use this address'),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddAddressDialog(
    BuildContext context,
    AddressProvider addressProvider,
    Function(Address) onAddressAdded,
  ) {
    final labelController = TextEditingController();
    final line1Controller = TextEditingController();
    final cityController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Address Label (e.g., Home, Work)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: line1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (labelController.text.trim().isNotEmpty &&
                    line1Controller.text.trim().isNotEmpty &&
                    cityController.text.trim().isNotEmpty &&
                    phoneController.text.trim().isNotEmpty) {
                  final newAddress = Address(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    label: labelController.text.trim(),
                    line1: line1Controller.text.trim(),
                    city: cityController.text.trim(),
                    phone: phoneController.text.trim(),
                  );
                  addressProvider.addAddress(newAddress);
                  onAddressAdded(newAddress);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Address added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add Address'),
            ),
          ],
        );
      },
    );
  }

  void _showMapAddressDialog(
    BuildContext context,
    AddressProvider addressProvider,
    Function(Address) onAddressAdded,
  ) async {
    final MapLocation? selectedLocation = await Navigator.of(context)
        .push<MapLocation>(
          MaterialPageRoute(builder: (context) => const GisMapPicker()),
        );

    if (selectedLocation != null) {
      final labelController = TextEditingController();
      final phoneController = TextEditingController();
      String? addressString;
      String? placeName;

      // Get address from coordinates
      addressString = await LocationService().getAddressFromCoordinates(
        selectedLocation,
      );

      // Get place name from coordinates for auto-fill
      placeName = await LocationService().getPlaceNameFromCoordinates(
        selectedLocation,
      );

      // Auto-fill label with place name if available
      if (placeName != null && placeName.isNotEmpty) {
        labelController.text = placeName;
      }
      if ((placeName == null || placeName.isEmpty) &&
          addressString != null &&
          addressString.isNotEmpty) {
        labelController.text = addressString;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add Address from Map'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Address Label (e.g., Home, Work)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      hintText: 'Will be filled automatically',
                    ),
                    maxLines: 2,
                    readOnly: true,
                    controller: TextEditingController(
                      text: addressString ?? 'Fetching address...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Location: ${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final labelText = labelController.text.trim().isNotEmpty
                      ? labelController.text.trim()
                      : (placeName?.trim().isNotEmpty == true
                          ? placeName!.trim()
                          : (addressString?.trim().isNotEmpty == true
                              ? addressString!.trim()
                              : 'Pinned Location'));
                  final addressText = addressString ??
                      'Location: ${selectedLocation.latitude.toStringAsFixed(4)}, ${selectedLocation.longitude.toStringAsFixed(4)}';

                  if (phoneController.text.trim().isNotEmpty &&
                      addressText.trim().isNotEmpty) {
                    final newAddress = Address(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      label: labelText,
                      line1: addressText,
                      city: '',
                      phone: phoneController.text.trim(),
                      latitude: selectedLocation.latitude,
                      longitude: selectedLocation.longitude,
                    );
                    addressProvider.addAddress(newAddress);
                    onAddressAdded(newAddress);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Add Address'),
              ),
            ],
          );
        },
      );
    }
  }

  void _confirmDeleteAddress(
    BuildContext context,
    Address address,
    AddressProvider addressProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Address'),
          content: Text('Are you sure you want to delete ${address.label}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                addressProvider.removeAddress(address.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
