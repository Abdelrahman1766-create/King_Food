import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../app/driver_app.dart';
import '../../../restaurant_admin/core/admin_constants.dart';
import '../../../utils/i18n.dart';

/// شاشة تفاصيل الطلب للسائق.
class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  YandexMapController? _mapController;
  Point? _pickupPoint;
  bool _isLoadingPickup = false;

  Future<void> _moveCameraTo(Point point) async {
    if (_mapController == null) return;
    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 16)),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.4,
      ),
    );
  }

  List<MapObject> _buildMapObjects(Point? deliveryPoint, Point? pickupPoint) {
    final objects = <MapObject>[];
    if (pickupPoint != null) {
      objects.add(
        CircleMapObject(
          mapId: const MapObjectId('pickup_point'),
          circle: Circle(center: pickupPoint, radius: 12),
          strokeColor: Colors.blue,
          strokeWidth: 2,
          fillColor: Colors.blue.withValues(alpha: 0.2),
        ),
      );
    }
    if (deliveryPoint != null) {
      objects.add(
        CircleMapObject(
          mapId: const MapObjectId('delivery_point'),
          circle: Circle(center: deliveryPoint, radius: 12),
          strokeColor: Colors.red,
          strokeWidth: 2,
          fillColor: Colors.red.withValues(alpha: 0.2),
        ),
      );
    }
    if (pickupPoint != null && deliveryPoint != null) {
      objects.add(
        PolylineMapObject(
          mapId: const MapObjectId('route_line'),
          polyline: Polyline(points: [pickupPoint, deliveryPoint]),
          strokeColor: Colors.green,
          strokeWidth: 3,
        ),
      );
    }
    return objects;
  }

  Future<void> _moveCameraToFit({
    required Point? deliveryPoint,
    required Point? pickupPoint,
  }) async {
    if (_mapController == null) return;
    if (deliveryPoint == null && pickupPoint == null) return;
    if (deliveryPoint != null && pickupPoint != null) {
      final center = Point(
        latitude: (deliveryPoint.latitude + pickupPoint.latitude) / 2,
        longitude: (deliveryPoint.longitude + pickupPoint.longitude) / 2,
      );
      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: 12),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 0.4,
        ),
      );
      return;
    }
    await _moveCameraTo(deliveryPoint ?? pickupPoint!);
  }

  Future<void> _loadPickupPoint(Point? hint) async {
    if (_isLoadingPickup || _pickupPoint != null) return;
    _isLoadingPickup = true;
    try {
      final geometry = Geometry.fromPoint(
        hint ?? const Point(latitude: 55.8304, longitude: 49.0661),
      );
      final (session, resultFuture) = await YandexSearch.searchByText(
        searchText: AdminConstants.restaurantAddress,
        geometry: geometry,
        searchOptions: const SearchOptions(
          searchType: SearchType.geo,
          resultPageSize: 1,
        ),
      );
      final result = await resultFuture;
      await session.close();

      if (result.items != null && result.items!.isNotEmpty) {
        final item = result.items!.first;
        final pointGeometry = item.geometry.firstWhere(
          (g) => g.point != null,
          orElse: () => Geometry.fromPoint(
            hint ?? const Point(latitude: 55.8304, longitude: 49.0661),
          ),
        );
        if (pointGeometry.point != null) {
          if (mounted) {
            setState(() => _pickupPoint = pointGeometry.point);
          }
        }
      }
    } catch (_) {
      // Ignore pickup lookup errors.
    } finally {
      _isLoadingPickup = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersViewModelProvider);
    final matchingOrders = ordersState.activeOrders
        .where((o) => o.id == widget.orderId)
        .toList();
    final order = matchingOrders.isEmpty ? null : matchingOrders.first;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t(context, 'Order Details', 'Детали заказа')),
        ),
        body: Center(
          child: Text(t(context, 'Order not found', 'Заказ не найден')),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final deliveryPoint =
        (order.deliveryLat != null && order.deliveryLng != null)
        ? Point(latitude: order.deliveryLat!, longitude: order.deliveryLng!)
        : null;

    if (_pickupPoint == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPickupPoint(deliveryPoint);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'Order Details', 'Детали заказа')),
        actions: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Text(order.orderNumber),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${t(context, 'Order #', 'Заказ №')} ${order.orderNumber}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '${t(context, 'Status', 'Статус')}: ${statusLabel(context, order.status)}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t(context, 'Customer Info', 'Информация о клиенте'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('${t(context, 'Name', 'Имя')}: ${order.customerName}'),
                    Text(
                      '${t(context, 'Phone', 'Телефон')}: ${order.customerPhone}',
                    ),
                    Text(
                      '${t(context, 'Address', 'Адрес')}: ${order.customerAddress}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(context, 'Pickup Info', 'Информация о выдаче'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${t(context, 'Pickup address', 'Адрес ресторана')}: ${AdminConstants.restaurantAddress}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(context, 'Items', 'Товары'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...order.items.map<Widget>((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name} × ${item.quantity}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            Text(
                              '${item.price * item.quantity} RUB',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t(context, 'Total', 'Итого'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${order.totalPrice.toStringAsFixed(2)} RUB',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(context, 'Delivery Map', 'Карта доставки'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (deliveryPoint == null && _pickupPoint == null)
                      Text(
                        t(
                          context,
                          'Delivery location is not available for this order.',
                          'Место доставки недоступно для этого заказа.',
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: YandexMap(
                            onMapCreated: (controller) async {
                              _mapController = controller;
                              try {
                                await _mapController!.toggleUserLayer(
                                  visible: true,
                                  headingEnabled: true,
                                  autoZoomEnabled: false,
                                );
                                await _moveCameraToFit(
                                  deliveryPoint: deliveryPoint,
                                  pickupPoint: _pickupPoint,
                                );
                              } catch (e) {
                                debugPrint('Yandex map init failed: $e');
                                // Avoid app crash; let the map remain usable in basic mode.
                              }
                            },
                            mapObjects: _buildMapObjects(
                              deliveryPoint,
                              _pickupPoint,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(
                        context,
                        'Update Order Status',
                        'Обновить статус заказа',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: (() {
                        final currentStatus = order.status as String?;
                        const driverStatuses = ['on_the_way', 'delivered'];
                        final values = <String>[...driverStatuses];
                        if (currentStatus != null &&
                            !values.contains(currentStatus.toLowerCase())) {
                          values.insert(0, currentStatus.toLowerCase());
                        }
                        final uniqueValues = values.toSet().toList();
                        return uniqueValues.contains(
                              currentStatus?.toLowerCase(),
                            )
                            ? currentStatus?.toLowerCase()
                            : null;
                      })(),
                      decoration: InputDecoration(
                        labelText: t(
                          context,
                          'Current status',
                          'Текущий статус',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: () {
                        final currentStatus = order.status as String?;
                        const driverStatuses = ['on_the_way', 'delivered'];
                        final values = <String>[...driverStatuses];
                        if (currentStatus != null &&
                            !values.contains(currentStatus.toLowerCase())) {
                          values.insert(0, currentStatus.toLowerCase());
                        }
                        final uniqueValues = values.toSet().toList();
                        return uniqueValues
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(statusLabel(context, value)),
                              ),
                            )
                            .toList();
                      }(),
                      onChanged: (value) {
                        if (value == null || value == order.status) return;
                        const driverStatuses = ['on_the_way', 'delivered'];
                        if (!driverStatuses.contains(value.toLowerCase())) {
                          return;
                        }
                        ref
                            .read(ordersViewModelProvider.notifier)
                            .updateOrderStatus(
                              orderId: order.id,
                              status: value.toLowerCase(),
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (deliveryPoint == null && _pickupPoint == null)
                        ? null
                        : () => _moveCameraToFit(
                            deliveryPoint: deliveryPoint,
                            pickupPoint: _pickupPoint,
                          ),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(t(context, 'Center Map', 'К карте')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t(
                              context,
                              'Customer call will be added soon.',
                              'Звонок клиенту скоро будет добавлен.',
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone_outlined),
                    label: Text(t(context, 'Call', 'Позвонить')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
