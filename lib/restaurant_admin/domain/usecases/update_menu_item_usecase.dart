import '../entities/menu_item.dart';
import '../repositories/menu_repository.dart';

/// UseCase لتحديث بيانات صنف موجود.
class UpdateMenuItemUseCase {
  UpdateMenuItemUseCase(this._repository);

  final MenuRepository _repository;

  Future<void> call({
    required String restaurantId,
    required MenuItemEntity item,
  }) {
    return _repository.updateMenuItem(
      restaurantId: restaurantId,
      item: item,
    );
  }
}
