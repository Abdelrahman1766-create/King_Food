import '../repositories/auth_repository.dart';

/// UseCase للتحقق من امتلاك المستخدم الحالي لدور مسؤول مطعم.
class CheckAdminRoleUseCase {
  CheckAdminRoleUseCase(this._repository);

  final AuthRepository _repository;

  Future<bool> call() {
    return _repository.hasRestaurantRole();
  }
}
