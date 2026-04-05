import '../entities/order.dart';
import '../repositories/orders_repository.dart';

/// UseCase للبحث عن الطلبات حسب رقم الطلب أو اسم العميل.
class SearchOrdersUseCase {
  SearchOrdersUseCase(this._repository);

  final OrdersRepository _repository;

  Future<List<Order>> call({
    required String restaurantId,
    String? orderNumber,
    String? customerName,
  }) {
    return _repository.searchOrders(
      restaurantId: restaurantId,
      orderNumber: orderNumber,
      customerName: customerName,
    );
  }
}
