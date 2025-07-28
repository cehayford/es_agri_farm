import 'productor_controller.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartController {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  void addToCart(Product product) {
    final index =
        _items.indexWhere((item) => item.product.name == product.name);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
  }

  void removeFromCart(Product product) {
    _items.removeWhere((item) => item.product.name == product.name);
  }

  void increaseQuantity(Product product) {
    final index =
        _items.indexWhere((item) => item.product.name == product.name);
    if (index != -1) {
      _items[index].quantity++;
    }
  }

  void decreaseQuantity(Product product) {
    final index =
        _items.indexWhere((item) => item.product.name == product.name);
    if (index != -1 && _items[index].quantity > 1) {
      _items[index].quantity--;
    } else if (index != -1) {
      removeFromCart(product);
    }
  }

  void clearCart() {
    _items.clear();
  }

  double get totalCost =>
      _items.fold(0, (sum, item) => sum + item.product.price * item.quantity);
}
