import 'package:equatable/equatable.dart';

/// يمثل سجل تغيير سعر لصنف معين.
class PriceLog extends Equatable {
  const PriceLog({
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

  @override
  List<Object?> get props => [
        id,
        itemId,
        oldPrice,
        newPrice,
        changedBy,
        changedAt,
        note,
      ];
}
