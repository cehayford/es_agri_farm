import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/category_controller.dart';
import '../../../models/product_model.dart';
import '../../../utils/utils.dart';
import '../../../widgets/widgets.dart';

class AdminProductFormScreen extends StatefulWidget {
  final String? productId;

  const AdminProductFormScreen({
    super.key,
    this.productId,
  });

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _tagsController = TextEditingController();

  // Livestock fields
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _weightController = TextEditingController();
  final _healthStatusController = TextEditingController();

  // Plant fields
  final _plantTypeController = TextEditingController();
  final _growthStageController = TextEditingController();
  final _careInstructionsController = TextEditingController();
  final _harvestSeasonController = TextEditingController();

  String _selectedCategoryId = '';
  bool _inStock = true;
  bool _isLivestock = false;
  bool _isPlant = false;
  bool _isVaccinated = false;
  bool _isOrganic = false;

  List<File> _newImageFiles = [];
  List<String> _existingImageUrls = [];

  bool _isUploading = false;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _quantityController.dispose();
    _tagsController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _weightController.dispose();
    _healthStatusController.dispose();
    _plantTypeController.dispose();
    _growthStageController.dispose();
    _careInstructionsController.dispose();
    _harvestSeasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final categoryController = Provider.of<CategoryController>(context, listen: false);
    final productController = Provider.of<ProductController>(context, listen: false);

    // Ensure categories are loaded
    if (categoryController.categories.isEmpty) {
      await categoryController.fetchCategories();
    }

    // Set default category if available
    if (categoryController.categories.isNotEmpty) {
      _selectedCategoryId = categoryController.categories.first.id;
    }

    // If editing an existing product, load its data
    if (widget.productId != null) {
      // Ensure products are loaded
      if (productController.products.isEmpty) {
        await productController.fetchProducts();
      }

      final product = productController.getProductById(widget.productId!);
      if (product != null) {
        _populateForm(product);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _populateForm(ProductModel product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _discountPriceController.text = product.discountPrice?.toString() ?? '';
    _quantityController.text = product.quantity.toString();
    _tagsController.text = product.tags.join(', ');
    _selectedCategoryId = product.categoryId;
    _inStock = product.inStock;
    _existingImageUrls = List<String>.from(product.imageUrls);

    // Livestock fields
    if (product.isLivestock) {
      _isLivestock = true;
      _breedController.text = product.breed ?? '';
      _ageController.text = product.age ?? '';
      _genderController.text = product.gender ?? '';
      _weightController.text = product.weight?.toString() ?? '';
      _isVaccinated = product.isVaccinated ?? false;
      _healthStatusController.text = product.healthStatus ?? '';
    }

    // Plant fields
    if (product.isPlant) {
      _isPlant = true;
      _plantTypeController.text = product.plantType ?? '';
      _growthStageController.text = product.growthStage ?? '';
      _careInstructionsController.text = product.careInstructions ?? '';
      _harvestSeasonController.text = product.harvestSeason ?? '';
      _isOrganic = product.isOrganic ?? false;
    }
  }

  Future<void> _pickImages() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _newImageFiles.addAll(images.map((image) => File(image.path)).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final productController = Provider.of<ProductController>(context, listen: false);
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final discountPrice = _discountPriceController.text.isEmpty
          ? null
          : double.tryParse(_discountPriceController.text);
      final quantity = int.tryParse(_quantityController.text) ?? 0;

      // Process tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      bool success;
      if (widget.productId == null) {
        // Add new product
        success = await productController.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          discountPrice: discountPrice,
          quantity: quantity,
          inStock: _inStock,
          categoryId: _selectedCategoryId,
          imageFiles: _newImageFiles,
          tags: tags,
          breed: _isLivestock ? _breedController.text.trim() : null,
          age: _isLivestock ? _ageController.text.trim() : null,
          gender: _isLivestock ? _genderController.text.trim() : null,
          weight: _isLivestock && _weightController.text.isNotEmpty
              ? double.tryParse(_weightController.text)
              : null,
          isVaccinated: _isLivestock ? _isVaccinated : null,
          healthStatus: _isLivestock ? _healthStatusController.text.trim() : null,
          plantType: _isPlant ? _plantTypeController.text.trim() : null,
          growthStage: _isPlant ? _growthStageController.text.trim() : null,
          careInstructions: _isPlant ? _careInstructionsController.text.trim() : null,
          harvestSeason: _isPlant ? _harvestSeasonController.text.trim() : null,
          isOrganic: _isPlant ? _isOrganic : null,
        );
      } else {
        // Get current product to check if category changed
        final currentProduct = productController.getProductById(widget.productId!);
        final oldCategoryId = currentProduct?.categoryId ?? _selectedCategoryId;

        // Update existing product
        success = await productController.updateProduct(
          id: widget.productId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          discountPrice: discountPrice,
          quantity: quantity,
          inStock: _inStock,
          categoryId: _selectedCategoryId,
          oldCategoryId: oldCategoryId,
          newImageFiles: _newImageFiles.isEmpty ? null : _newImageFiles,
          existingImageUrls: _existingImageUrls,
          tags: tags,
          breed: _isLivestock ? _breedController.text.trim() : null,
          age: _isLivestock ? _ageController.text.trim() : null,
          gender: _isLivestock ? _genderController.text.trim() : null,
          weight: _isLivestock && _weightController.text.isNotEmpty
              ? double.tryParse(_weightController.text)
              : null,
          isVaccinated: _isLivestock ? _isVaccinated : null,
          healthStatus: _isLivestock ? _healthStatusController.text.trim() : null,
          plantType: _isPlant ? _plantTypeController.text.trim() : null,
          growthStage: _isPlant ? _growthStageController.text.trim() : null,
          careInstructions: _isPlant ? _careInstructionsController.text.trim() : null,
          harvestSeason: _isPlant ? _harvestSeasonController.text.trim() : null,
          isOrganic: _isPlant ? _isOrganic : null,
        );
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.productId == null
                    ? 'Product added successfully!'
                    : 'Product updated successfully!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save product: ${productController.error}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() {
            _isSaving = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add Product' : 'Edit Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic information section
                    const Text(
                      'Basic Information',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 16),

                    // Product name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        hintText: 'Enter product name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    Consumer<CategoryController>(
                      builder: (context, categoryController, _) {
                        final categories = categoryController.categories;

                        if (categories.isEmpty) {
                          return const Text(
                            'No categories available. Please create a category first.',
                            style: TextStyle(color: AppColors.error),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product type selection
                    const Text(
                      'Product Type (Optional)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Livestock'),
                            value: _isLivestock,
                            onChanged: (value) {
                              setState(() {
                                _isLivestock = value ?? false;
                                // Disable plant if livestock is selected
                                if (_isLivestock) {
                                  _isPlant = false;
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Plant'),
                            value: _isPlant,
                            onChanged: (value) {
                              setState(() {
                                _isPlant = value ?? false;
                                // Disable livestock if plant is selected
                                if (_isPlant) {
                                  _isLivestock = false;
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter product description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price and stock section
                    const Text(
                      'Price & Stock',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 16),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        hintText: 'Enter price',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Price must be greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Discount price (optional)
                    TextFormField(
                      controller: _discountPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Discount Price (\$) (Optional)',
                        hintText: 'Enter discount price',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money_off),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          final price = double.tryParse(_priceController.text) ?? 0;
                          final discount = double.parse(value);
                          if (discount >= price) {
                            return 'Discount price must be less than regular price';
                          }
                          if (discount <= 0) {
                            return 'Discount price must be greater than zero';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: 'Enter quantity in stock',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (int.parse(value) < 0) {
                          return 'Quantity cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // In stock switch
                    SwitchListTile(
                      title: const Text('Available in Stock'),
                      subtitle: const Text('Turn off if this product is currently unavailable'),
                      value: _inStock,
                      onChanged: (value) {
                        setState(() {
                          _inStock = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (Optional)',
                        hintText: 'Enter tags separated by commas',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Product images section
                    const Text(
                      'Product Images',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload multiple images of your product. The first image will be the main image.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Existing images
                    if (_existingImageUrls.isNotEmpty) ...[
                      const Text(
                        'Current Images',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImageUrls.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.lightGrey),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _existingImageUrls[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(Icons.image_not_supported),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 8,
                                  child: InkWell(
                                    onTap: () => _removeExistingImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // New images
                    if (_newImageFiles.isNotEmpty) ...[
                      const Text(
                        'New Images',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newImageFiles.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.lightGrey),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _newImageFiles[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 8,
                                  child: InkWell(
                                    onTap: () => _removeNewImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Add image button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickImages,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_photo_alternate),
                        label: Text(_isUploading ? 'Uploading...' : 'Add Images'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Livestock details section (conditional)
                    if (_isLivestock) ...[
                      const Text(
                        'Livestock Details',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 16),

                      // Breed
                      TextFormField(
                        controller: _breedController,
                        decoration: const InputDecoration(
                          labelText: 'Breed',
                          hintText: 'Enter breed name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Age
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          hintText: 'Enter age (e.g., "2 years")',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      TextFormField(
                        controller: _genderController,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          hintText: 'Enter gender',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Weight
                      TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          hintText: 'Enter weight in kg',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Weight must be greater than zero';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Vaccinated
                      SwitchListTile(
                        title: const Text('Vaccinated'),
                        value: _isVaccinated,
                        onChanged: (value) {
                          setState(() {
                            _isVaccinated = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Health status
                      TextFormField(
                        controller: _healthStatusController,
                        decoration: const InputDecoration(
                          labelText: 'Health Status',
                          hintText: 'Enter health status',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Plant details section (conditional)
                    if (_isPlant) ...[
                      const Text(
                        'Plant Details',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 16),

                      // Plant type
                      TextFormField(
                        controller: _plantTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Plant Type',
                          hintText: 'Enter plant type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Growth stage
                      TextFormField(
                        controller: _growthStageController,
                        decoration: const InputDecoration(
                          labelText: 'Growth Stage',
                          hintText: 'Enter growth stage',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Care instructions
                      TextFormField(
                        controller: _careInstructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Care Instructions',
                          hintText: 'Enter care instructions',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Harvest season
                      TextFormField(
                        controller: _harvestSeasonController,
                        decoration: const InputDecoration(
                          labelText: 'Harvest Season',
                          hintText: 'Enter harvest season',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Organic
                      SwitchListTile(
                        title: const Text('Organic'),
                        value: _isOrganic,
                        onChanged: (value) {
                          setState(() {
                            _isOrganic = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(widget.productId == null ? 'Creating...' : 'Updating...'),
                                ],
                              )
                            : Text(widget.productId == null ? 'Create Product' : 'Update Product'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
