import '../repositories/menu_repository.dart';

/// UseCase لرفع صورة صنف وإرجاع رابطها.
class UploadItemImageUseCase {
  UploadItemImageUseCase(this._repository);

  final MenuRepository _repository;

  Future<String> call({
    required String restaurantId,
    required String filePath,
  }) {
    return _repository.uploadItemImage(
      restaurantId: restaurantId,
      filePath: filePath,
    );
  }
}
