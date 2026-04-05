class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  int quantity;

  FoodItem({
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    this.quantity = 1,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();

  double get totalPrice => price * quantity;

  FoodItem copyWith({int? quantity}) {
    return FoodItem(
      name: name,
      description: description,
      price: price,
      image: image,
      category: category,
      quantity: quantity ?? this.quantity,
    );
  }
}
