import 'dart:convert';
import 'package:http/http.dart' as http;

class Product {
  final String name;
  final double price;
  final String description;
  final DateTime dateCreated;
  final String imageUrl;


  Product({
    required this.name,
    required this.price,
    required this.description,
    required this.dateCreated,
    required this.imageUrl, 
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        name: json['name'],
        price: json['price'].toDouble(),
        description: json['description'],
        dateCreated: DateTime.parse(json['date_created']),
        imageUrl: json['image_url'],
      );
}

class ProductController {
  Future<List<Product>> fetchProducts() async {
    final response =
        await http.get(Uri.parse('https://example.com/api/products'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
}
