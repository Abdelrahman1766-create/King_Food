import '../entities/price_log.dart';
import '../repositories/menu_repository.dart';

/// UseCase لتسجيل تغيير سعر صنف.
class LogPriceChangeUseCase {
  LogPriceChangeUseCase(this._repository);

  final MenuRepository _repository;

  Future<void> call({
    required String restaurantId,
    required PriceLog log,
  }) {
    return _repository.logPriceChange(
      restaurantId: restaurantId,
      log: log,
    );
  }
}
