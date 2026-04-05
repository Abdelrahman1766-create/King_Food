import '../repositories/auth_repository.dart';

/// UseCase لتسجيل خروج مسؤول المطعم.
class SignOutUseCase {
  SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() {
    return _repository.signOut();
  }
}
