class Address {
  final String id;
  final String label; // Home, Work, etc.
  final String line1;
  final String? line2;
  final String city;
  final String phone;
  final double? latitude;
  final double? longitude;

  const Address({
    required this.id,
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    required this.phone,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      label: json['label'],
      line1: json['line1'],
      line2: json['line2'],
      city: json['city'],
      phone: json['phone'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'line1': line1,
      'line2': line2,
      'city': city,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

final demoAddresses = <Address>[
  Address(
    id: 'a1',
    label: 'Home',
    line1: '123 Main St',
    city: 'City',
    phone: '+1000000000',
  ),
];
