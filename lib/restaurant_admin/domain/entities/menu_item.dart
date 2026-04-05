import 'package:equatable/equatable.dart';

/// كيان يمثل صنف في قائمة المطعم.
class MenuItemEntity extends Equatable {
  const MenuItemEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItemEntity copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    description,
    imageUrl,
    isAvailable,
    createdAt,
    updatedAt,
  ];
}
