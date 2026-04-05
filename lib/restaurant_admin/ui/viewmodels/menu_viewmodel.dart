import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/admin_providers.dart';
import '../../core/admin_failures.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/price_log.dart';
import '../../domain/usecases/watch_menu_items_usecase.dart';
import '../../domain/usecases/add_menu_item_usecase.dart';
import '../../domain/usecases/update_menu_item_usecase.dart';
import '../../domain/usecases/delete_menu_item_usecase.dart';
import '../../domain/usecases/upload_item_image_usecase.dart';
import '../../domain/usecases/log_price_change_usecase.dart';
import '../../domain/usecases/get_price_logs_usecase.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../utils/i18n.dart';

/// حالة إدارة الأصناف.
class MenuState {
  const MenuState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.uploadingImage = false,
    this.priceLogs = const [],
  });

  final List<MenuItemEntity> items;
  final bool isLoading;
  final String? errorMessage;
  final bool uploadingImage;
  final List<PriceLog> priceLogs;

  MenuState copyWith({
    List<MenuItemEntity>? items,
    bool? isLoading,
    String? errorMessage,
    bool? uploadingImage,
    List<PriceLog>? priceLogs,
  }) {
    return MenuState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      uploadingImage: uploadingImage ?? this.uploadingImage,
      priceLogs: priceLogs ?? this.priceLogs,
    );
  }
}

/// ViewModel لإدارة أصناف المطعم.
class MenuViewModel extends StateNotifier<MenuState> {
  MenuViewModel(
    this._watchMenuItems,
    this._addMenuItem,
    this._updateMenuItem,
    this._deleteMenuItem,
    this._uploadImage,
    this._logPriceChange,
    this._getPriceLogs,
  ) : super(const MenuState());

  final WatchMenuItemsUseCase _watchMenuItems;
  final AddMenuItemUseCase _addMenuItem;
  final UpdateMenuItemUseCase _updateMenuItem;
  final DeleteMenuItemUseCase _deleteMenuItem;
  final UploadItemImageUseCase _uploadImage;
  final LogPriceChangeUseCase _logPriceChange;
  final GetPriceLogsUseCase _getPriceLogs;

  StreamSubscription<List<MenuItemEntity>>? _menuSub;
  String? _restaurantId;

  void initialize(String restaurantId) {
    if (_restaurantId == restaurantId) return;
    _restaurantId = restaurantId;
    _listenMenuItems();
  }

  void _listenMenuItems() {
    if (_restaurantId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    _menuSub?.cancel();
    _menuSub = _watchMenuItems(restaurantId: _restaurantId!).listen((items) {
      state = state.copyWith(items: items, isLoading: false, errorMessage: null);
    }, onError: (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: tNoContext(
          'Failed to load items: $error',
          'Не удалось загрузить товары: $error',
        ),
      );
    });
  }

  Future<void> addMenuItem(MenuItemEntity item) async {
    if (_restaurantId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _addMenuItem(
        restaurantId: _restaurantId!,
        item: item,
      );
      state = state.copyWith(isLoading: false);
    } on Failure catch (failure) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: tNoContext(
          'Failed to add item: $error',
          'Не удалось добавить товар: $error',
        ),
      );
    }
  }

  Future<void> updateMenuItem(MenuItemEntity item, {double? oldPrice}) async {
    if (_restaurantId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _updateMenuItem(
        restaurantId: _restaurantId!,
        item: item,
      );
      state = state.copyWith(isLoading: false);
      if (oldPrice != null && oldPrice != item.price) {
        final log = PriceLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          itemId: item.id,
          oldPrice: oldPrice,
          newPrice: item.price,
          changedBy: _restaurantId!,
          changedAt: DateTime.now(),
        );
        await _logPriceChange(
          restaurantId: _restaurantId!,
          log: log,
        );
      }
    } on Failure catch (failure) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: tNoContext(
          'Failed to update item: $error',
          'Не удалось обновить товар: $error',
        ),
      );
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    if (_restaurantId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _deleteMenuItem(
        restaurantId: _restaurantId!,
        itemId: itemId,
      );
      state = state.copyWith(isLoading: false);
    } on Failure catch (failure) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: tNoContext(
          'Failed to delete item: $error',
          'Не удалось удалить товар: $error',
        ),
      );
    }
  }

  Future<String?> uploadImage(File? file) async {
    if (_restaurantId == null || file == null) return null;
    state = state.copyWith(uploadingImage: true, errorMessage: null);
    try {
      final url = await _uploadImage(
        restaurantId: _restaurantId!,
        filePath: file.path,
      );
      state = state.copyWith(uploadingImage: false);
      return url;
    } on Failure catch (failure) {
      state = state.copyWith(
        uploadingImage: false,
        errorMessage: failure.message,
      );
      return null;
    } catch (error) {
      state = state.copyWith(
        uploadingImage: false,
        errorMessage: tNoContext(
          'Failed to upload image: $error',
          'Не удалось загрузить изображение: $error',
        ),
      );
      return null;
    }
  }

  Future<void> loadPriceLogs(String itemId) async {
    if (_restaurantId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final logs = await _getPriceLogs(
        restaurantId: _restaurantId!,
        itemId: itemId,
      );
      state = state.copyWith(isLoading: false, priceLogs: logs);
    } on Failure catch (failure) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: tNoContext(
          'Failed to load price log: $error',
          'Не удалось загрузить историю цен: $error',
        ),
      );
    }
  }

  @override
  void dispose() {
    _menuSub?.cancel();
    super.dispose();
  }
}

final menuViewModelProvider =
    StateNotifierProvider.autoDispose<MenuViewModel, MenuState>((ref) {
  final viewModel = MenuViewModel(
    ref.watch(watchMenuItemsUseCaseProvider),
    ref.watch(addMenuItemUseCaseProvider),
    ref.watch(updateMenuItemUseCaseProvider),
    ref.watch(deleteMenuItemUseCaseProvider),
    ref.watch(uploadItemImageUseCaseProvider),
    ref.watch(logPriceChangeUseCaseProvider),
    ref.watch(getPriceLogsUseCaseProvider),
  );

  ref.listen<AuthState>(authViewModelProvider, (_, state) {
    final restaurantId = state.restaurantId;
    if (restaurantId != null) {
      viewModel.initialize(restaurantId);
    }
  });

  final authState = ref.read(authViewModelProvider);
  final restaurantId = authState.restaurantId;
  if (restaurantId != null) {
    viewModel.initialize(restaurantId);
  }

  return viewModel;
});
