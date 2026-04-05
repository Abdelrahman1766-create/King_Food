import '../repositories/auth_repository.dart';

/// UseCase للحصول على معرف المطعم المرتبط بالمستخدم الحالي.
class GetRestaurantIdUseCase {
  GetRestaurantIdUseCase(this._repository);

  final AuthRepository _repository;

  Future<String> call() {
    return _repository.getRestaurantId();
  }
}
