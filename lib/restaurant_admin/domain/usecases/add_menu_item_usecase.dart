import '../entities/menu_item.dart';
import '../repositories/menu_repository.dart';

/// UseCase لإضافة صنف جديد إلى قائمة المطعم.
class AddMenuItemUseCase {
  AddMenuItemUseCase(this._repository);

  final MenuRepository _repository;

  Future<void> call({
    required String restaurantId,
    required MenuItemEntity item,
  }) {
    return _repository.addMenuItem(
      restaurantId: restaurantId,
      item: item,
    );
  }
}
