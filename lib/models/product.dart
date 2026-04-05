class Product {
  final String id;
  final String name;
  final String category; // fries, sandwiches, meals, drinks
  final double price;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.imageUrl,
  });
}

const demoProducts = <Product>[
  // Fries
  Product(
    id: 'f1',
    name: 'Classic Fries',
    category: 'fries',
    price: 134.9,
    imageUrl: 'assets/food_images/CLASSIC_FRIES.jpg',
  ),
  Product(
    id: 'f2',
    name: 'Cheese Fries',
    category: 'fries',
    price: 164.9,
    imageUrl: 'assets/food_images/CHEESE_FRIES.jpg',
  ),
  Product(
    id: 'f3',
    name: 'Spicy Fries',
    category: 'fries',
    price: 144.9,
    imageUrl: 'assets/food_images/SPICY_FRIES.jpg',
  ),

  // Sandwiches
  Product(
    id: 's1',
    name: 'Chicken Shawarma',
    category: 'sandwiches',
    price: 259.9,
    imageUrl: 'assets/food_images/CHICKEN_SHAWARMA.jpg',
  ),
  Product(
    id: 's2',
    name: 'Beef Burger',
    category: 'sandwiches',
    price: 239.0,
    imageUrl: 'assets/food_images/BEEF_BURGER.jpg',
  ),
  Product(
    id: 's3',
    name: 'Chicken Burger',
    category: 'sandwiches',
    price: 199.0,
    imageUrl: 'assets/food_images/CHICKEN_BURGER.jpg',
  ),
  Product(
    id: 's4',
    name: 'Strips Chickens',
    category: 'sandwiches',
    price: 229.9,
    imageUrl: 'assets/food_images/STRIPS_CHICKENS.jpg',
  ),

  // Main Meals
  Product(
    id: 'm1',
    name: 'Chicken Kabsa',
    category: 'meals',
    price: 359.9,
    imageUrl: 'assets/food_images/CHICKEN_KABSA.jpg',
  ),
  Product(
    id: 'm2',
    name: 'Burger Meal',
    category: 'meals',
    price: 329.9,
    imageUrl: 'assets/food_images/BURGER_MEAL.jpg',
  ),
  Product(
    id: 'm3',
    name: 'Pizza Margherita',
    category: 'meals',
    price: 409.9,
    imageUrl: 'assets/food_images/PIZZA_MARGHERITA.jpeg',
  ),
  Product(
    id: 'm5',
    name: 'Arabian Pizza ',
    category: 'meals',
    price: 499,
    imageUrl: 'assets/food_images/CHICKEN-PIZZA.jpg',
  ),

  Product(
    id: 'm4',
    name: 'Makarona Bachamel',
    category: 'meals',
    price: 259.9,
    imageUrl: 'assets/food_images/Makarone Bachamel.jpg',
  ),

  // Drinks
  Product(
    id: 'd1',
    name: 'Coca Cola',
    category: 'drinks',
    price: 99,
    imageUrl: 'assets/food_images/COLA.jpg',
  ),
  // Product(
  // id: 'd2',
  //name: 'Orange Juice',
  //category: 'drinks',
  //price: 99,
  //imageUrl: 'assets/food_images/ORANGE_COLA.jpg',
  //),
  Product(
    id: 'd3',
    name: ' Water',
    category: 'drinks',
    price: 59,
    imageUrl: 'assets/food_images/WATER.jpg',
  ),
  // Product(
  // id: 'd4',
  //name: 'Pepsi',
  //category: 'drinks',
  //price: 99,
  //imageUrl: 'assets/food_images/fries.jpg',
  //),
  Product(
    id: 'd5',
    name: 'Apple Juice',
    category: 'drinks',
    price: 79,
    imageUrl: 'assets/food_images/APPLE_JUICE.jpeg',
  ),

  // Desserts
  Product(
    id: 'c1',
    name: 'Ice Cream',
    category: 'desserts',
    price: 84,
    imageUrl: 'assets/food_images/ICE_CREAM.jpg',
  ),
  // Product(
  //id: 'c2',
  //name: 'Cake',
  //category: 'desserts',
  //price: 119,
  //imageUrl: 'assets/food_images/fries.jpg',
  //),
  // Product(
  // id: 'c3',
  //name: 'Kunafa',
  //category: 'desserts',
  //price: 139,
  //imageUrl: 'assets/food_images/fries.jpg',
  //),
];
