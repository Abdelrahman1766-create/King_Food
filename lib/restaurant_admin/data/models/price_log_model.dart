import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/price_log.dart';

/// نموذج سجل تغيير السعر.
class PriceLogModel {
  const PriceLogModel({
    required this.id,
    required this.itemId,
    required this.oldPrice,
    required this.newPrice,
    required this.changedBy,
    required this.changedAt,
    this.note,
  });

  final String id;
  final String itemId;
  final double oldPrice;
  final double newPrice;
  final String changedBy;
  final DateTime changedAt;
  final String? note;

  factory PriceLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PriceLogModel(
      id: doc.id,
      itemId: data['itemId'] as String? ?? '',
      oldPrice: (data['oldPrice'] as num?)?.toDouble() ?? 0.0,
      newPrice: (data['newPrice'] as num?)?.toDouble() ?? 0.0,
      changedBy: data['changedBy'] as String? ?? '',
      changedAt: (data['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String?,
    );
  }

  factory PriceLogModel.fromEntity(PriceLog entity) {
    return PriceLogModel(
      id: entity.id,
      itemId: entity.itemId,
      oldPrice: entity.oldPrice,
      newPrice: entity.newPrice,
      changedBy: entity.changedBy,
      changedAt: entity.changedAt,
      note: entity.note,
    );
  }

  PriceLog toEntity() {
    return PriceLog(
      id: id,
      itemId: itemId,
      oldPrice: oldPrice,
      newPrice: newPrice,
      changedBy: changedBy,
      changedAt: changedAt,
      note: note,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'changedBy': changedBy,
      'changedAt': Timestamp.fromDate(changedAt),
      if (note != null) 'note': note,
    };
  }
}
