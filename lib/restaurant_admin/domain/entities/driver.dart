/// Ù†Ù…ÙˆØ°Ø¬ Ø§Ù„Ø³Ø§Ø¦Ù‚
class Driver {
  final String id;
  final String name;
  final String phone;
  final bool isAvailable;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'phone': phone, 'isAvailable': isAvailable};
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}

final demoDrivers = <Driver>[
  Driver(
    id: 'Ra6j6HKnsdfsqn7x0Fwwnkf5Heu2',
    name: 'Алексей Смирнович',
    phone: '+79997216971',
    isAvailable: true,
  ),
  Driver(
    id: 'Y0m3Kw4wTPNXyo2JSxqots4Vqv22',
    name: 'Иван Иванович',
    phone: '+79053142448',
    isAvailable: true,
  ),
  Driver(
    id: 'd3',
    name: 'Вася Пупкин',
    phone: '+79161234567',
    isAvailable: false,
  ),
];
