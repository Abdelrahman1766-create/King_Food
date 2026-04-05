import '../entities/order.dart';
import '../repositories/orders_repository.dart';

/// UseCase لمراقبة الطلبات المكتملة مع إمكانية تحديد مجال التاريخ.
class WatchCompletedOrdersUseCase {
  WatchCompletedOrdersUseCase(this._repository);

  final OrdersRepository _repository;

  Stream<List<Order>> call({
    required String restaurantId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.watchCompletedOrders(
      restaurantId: restaurantId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
