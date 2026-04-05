import '../entities/menu_item.dart';
import '../repositories/menu_repository.dart';

/// UseCase لمراقبة أصناف قائمة الطعام بشكل لحظي.
class WatchMenuItemsUseCase {
  WatchMenuItemsUseCase(this._repository);

  final MenuRepository _repository;

  Stream<List<MenuItemEntity>> call({required String restaurantId}) {
    return _repository.watchMenuItems(restaurantId: restaurantId);
  }
}
