import '../repositories/menu_repository.dart';

/// UseCase لحذف صنف من قائمة المطعم.
class DeleteMenuItemUseCase {
  DeleteMenuItemUseCase(this._repository);

  final MenuRepository _repository;

  Future<void> call({
    required String restaurantId,
    required String itemId,
  }) {
    return _repository.deleteMenuItem(
      restaurantId: restaurantId,
      itemId: itemId,
    );
  }
}
