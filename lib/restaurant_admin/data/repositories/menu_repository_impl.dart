import '../../core/admin_failures.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/price_log.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_datasource.dart';
import '../models/menu_item_model.dart';
import '../models/price_log_model.dart';
import '../../../utils/i18n.dart';

/// تنفيذ مستودع إدارة الأصناف باستخدام Firestore وStorage.
class MenuRepositoryImpl implements MenuRepository {
  MenuRepositoryImpl(this._remoteDataSource);

  final MenuRemoteDataSource _remoteDataSource;

  @override
  Stream<List<MenuItemEntity>> watchMenuItems({required String restaurantId}) {
    return _remoteDataSource
        .watchMenuItems(restaurantId: restaurantId)
        .map((items) => items.map((e) => e.toEntity()).toList());
  }

  @override
  Future<void> addMenuItem({
    required String restaurantId,
    required MenuItemEntity item,
  }) async {
    try {
      final model = MenuItemModel.fromEntity(item);
      await _remoteDataSource.addMenuItem(
        restaurantId: restaurantId,
        item: model,
      );
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to add item: ${e.toString()}',
          'Не удалось добавить товар: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<void> updateMenuItem({
    required String restaurantId,
    required MenuItemEntity item,
  }) async {
    try {
      final model = MenuItemModel.fromEntity(item);
      await _remoteDataSource.updateMenuItem(
        restaurantId: restaurantId,
        item: model,
      );
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to update item: ${e.toString()}',
          'Не удалось обновить товар: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<void> deleteMenuItem({
    required String restaurantId,
    required String itemId,
  }) async {
    try {
      await _remoteDataSource.deleteMenuItem(
        restaurantId: restaurantId,
        itemId: itemId,
      );
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to delete item: ${e.toString()}',
          'Не удалось удалить товар: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<String> uploadItemImage({
    required String restaurantId,
    required String filePath,
  }) async {
    try {
      return _remoteDataSource.uploadItemImage(
        restaurantId: restaurantId,
        filePath: filePath,
      );
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to upload image: ${e.toString()}',
          'Не удалось загрузить изображение: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<void> logPriceChange({
    required String restaurantId,
    required PriceLog log,
  }) async {
    try {
      final model = PriceLogModel.fromEntity(log);
      await _remoteDataSource.logPriceChange(
        restaurantId: restaurantId,
        log: model,
      );
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to log price change: ${e.toString()}',
          'Не удалось сохранить изменение цены: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<List<PriceLog>> getPriceLogs({
    required String restaurantId,
    required String itemId,
  }) async {
    try {
      final logs = await _remoteDataSource.getPriceLogs(
        restaurantId: restaurantId,
        itemId: itemId,
      );
      return logs.map((e) => e.toEntity()).toList();
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to fetch price log: ${e.toString()}',
          'Не удалось получить историю цен: ${e.toString()}',
        ),
      );
    }
  }
}
