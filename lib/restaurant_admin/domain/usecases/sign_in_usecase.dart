import '../repositories/auth_repository.dart';

/// UseCase لتسجيل دخول مسؤول المطعم باستخدام البريد وكلمة المرور.
class SignInUseCase {
  SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email, required String password}) {
    return _repository.signIn(email: email, password: password);
  }
}
