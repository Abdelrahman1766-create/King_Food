import '../entities/order.dart';
import '../repositories/orders_repository.dart';

/// UseCase لمراقبة الطلبات النشطة للمطعم.
class WatchActiveOrdersUseCase {
  WatchActiveOrdersUseCase(this._repository);

  final OrdersRepository _repository;

  Stream<List<Order>> call({required String restaurantId}) {
    return _repository.watchActiveOrders(restaurantId: restaurantId);
  }
}
