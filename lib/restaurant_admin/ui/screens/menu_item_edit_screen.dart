import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/menu_item.dart';
import '../viewmodels/menu_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../utils/i18n.dart';

/// شاشة تعديل/إضافة صنف جديد.
class MenuItemEditScreen extends ConsumerStatefulWidget {
  const MenuItemEditScreen({super.key, this.itemId});

  final String? itemId;

  @override
  ConsumerState<MenuItemEditScreen> createState() => _MenuItemEditScreenState();
}

class _MenuItemEditScreenState extends ConsumerState<MenuItemEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImage;
  bool _isAvailable = true;
  String? _imageUrl;
  DateTime? _createdAt;
  double? _initialPrice;

  @override
  void initState() {
    super.initState();
    final menuState = ref.read(menuViewModelProvider);
    final itemId = widget.itemId;
    if (itemId != null) {
      final existingItem = menuState.items.firstWhere(
        (element) => element.id == itemId,
        orElse: () => MenuItemEntity(
          id: itemId,
          name: '',
          price: 0,
          description: '',
          imageUrl: '',
          isAvailable: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _nameController.text = existingItem.name;
      _priceController.text = existingItem.price.toString();
      _descriptionController.text = existingItem.description;
      _isAvailable = existingItem.isAvailable;
      _imageUrl = existingItem.imageUrl;
      _createdAt = existingItem.createdAt;
      _initialPrice = existingItem.price;
    } else {
      _createdAt = DateTime.now();
      _initialPrice = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final menuNotifier = ref.read(menuViewModelProvider.notifier);
    final authState = ref.read(authViewModelProvider);
    final restaurantId = authState.restaurantId;
    if (restaurantId == null) return;

    String imageUrl = _imageUrl ?? '';
    if (_selectedImage != null) {
      final uploadedUrl = await menuNotifier.uploadImage(_selectedImage!);
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      }
    }

    final item = MenuItemEntity(
      id: widget.itemId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      description: _descriptionController.text.trim(),
      imageUrl: imageUrl,
      isAvailable: _isAvailable,
      createdAt: _createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.itemId == null) {
      await menuNotifier.addMenuItem(item);
    } else {
      await menuNotifier.updateMenuItem(item, oldPrice: _initialPrice);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemId == null
              ? t(context, 'Add Item', 'Добавить товар')
              : t(context, 'Edit Item', 'Редактировать товар'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: InkWell(
                  onTap: menuState.uploadingImage ? null : _pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : (_imageUrl != null && _imageUrl!.isNotEmpty)
                        ? Image.network(
                            _imageUrl!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image, size: 48),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              );
                            },
                          )
                        : Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 48,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: t(context, 'Item name', 'Название товара'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t(
                      context,
                      'Please enter item name',
                      'Пожалуйста, введите название товара',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: t(context, 'Price', 'Цена'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return t(
                      context,
                      'Please enter a valid price greater than zero',
                      'Введите корректную цену больше нуля',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: t(context, 'Description', 'Описание'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t(
                      context,
                      'Please enter a description',
                      'Пожалуйста, введите описание',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(t(context, 'Available', 'В наличии')),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: menuState.isLoading ? null : _save,
                icon: menuState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  widget.itemId == null
                      ? t(context, 'Save Item', 'Сохранить товар')
                      : t(context, 'Update Item', 'Обновить товар'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
