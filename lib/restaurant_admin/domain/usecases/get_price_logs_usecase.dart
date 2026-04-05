import '../entities/price_log.dart';
import '../repositories/menu_repository.dart';

/// UseCase لجلب سجل تغييرات الأسعار لصنف معين.
class GetPriceLogsUseCase {
  GetPriceLogsUseCase(this._repository);

  final MenuRepository _repository;

  Future<List<PriceLog>> call({
    required String restaurantId,
    required String itemId,
  }) {
    return _repository.getPriceLogs(
      restaurantId: restaurantId,
      itemId: itemId,
    );
  }
}
