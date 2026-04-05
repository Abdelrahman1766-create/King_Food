import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/menu_item.dart';

/// نموذج صنف القائمة للفرق بين Firestore وكيان الدومين.
class MenuItemModel {
  const MenuItemModel({
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

  factory MenuItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MenuItemModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      isAvailable: data['isAvailable'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory MenuItemModel.fromEntity(MenuItemEntity entity) {
    return MenuItemModel(
      id: entity.id,
      name: entity.name,
      price: entity.price,
      description: entity.description,
      imageUrl: entity.imageUrl,
      isAvailable: entity.isAvailable,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  MenuItemEntity toEntity() {
    return MenuItemEntity(
      id: id,
      name: name,
      price: price,
      description: description,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
