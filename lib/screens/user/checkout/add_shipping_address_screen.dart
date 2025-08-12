import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/shipping_controller.dart';
import '../../../models/shipping_address_model.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/custom_text_field.dart';

class AddShippingAddressScreen extends StatefulWidget {
  final ShippingAddressModel? address;

  const AddShippingAddressScreen({
    super.key,
    this.address,
  });

  @override
  State<AddShippingAddressScreen> createState() => _AddShippingAddressScreenState();
}

class _AddShippingAddressScreenState extends State<AddShippingAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If editing an existing address, populate the form
    if (widget.address != null) {
      _fullNameController.text = widget.address!.fullName;
      _phoneController.text = widget.address!.phoneNumber;
      _addressLine1Controller.text = widget.address!.addressLine1;
      _addressLine2Controller.text = widget.address!.addressLine2 ?? '';
      _cityController.text = widget.address!.city;
      _stateController.text = widget.address!.state;
      _zipController.text = widget.address!.postalCode;
      _isDefault = widget.address!.isDefault;
    } else {
      // If it's the first address, make it default
      final shippingController = Provider.of<ShippingController>(context, listen: false);
      if (!shippingController.hasAddresses) {
        _isDefault = true;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  // Save address
  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final shippingController = Provider.of<ShippingController>(context, listen: false);

      final address = ShippingAddressModel(
        id: widget.address?.id ?? '',  // Empty for new address, will be set in controller
        userId: authController.user!.id,
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text.isEmpty ? null : _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        postalCode: _zipController.text,
        isDefault: _isDefault,
      );

      bool success;
      if (widget.address != null) {
        // Update existing address
        success = await shippingController.updateAddress(address);
      } else {
        // Add new address
        success = await shippingController.addAddress(address);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address saved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(shippingController.error),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address != null ? 'Edit Address' : 'Add Address'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Full Name',
                controller: _fullNameController,
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Phone Number',
                controller: _phoneController,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Address Line 1',
                controller: _addressLine1Controller,
                prefixIcon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Address Line 2 (Optional)',
                controller: _addressLine2Controller,
                prefixIcon: Icons.location_on,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'City',
                controller: _cityController,
                prefixIcon: Icons.location_city,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'State/Province',
                      controller: _stateController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your state';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'ZIP/Postal Code',
                      controller: _zipController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your ZIP code';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Make default checkbox
              CheckboxListTile(
                title: const Text('Set as default address'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('SAVE ADDRESS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
