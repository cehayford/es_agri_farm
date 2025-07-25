import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Product {
  final String name;
  final double price;
  final String description;
  final DateTime dateCreated;
  final String imageUrl;
  final String category; // Not nullable

  Product({
    required this.name,
    required this.price,
    required this.description,
    required this.dateCreated,
    required this.imageUrl,
    required this.category, // Not nullable
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        name: json['name'],
        price: json['price'].toDouble(),
        description: json['description'],
        dateCreated: DateTime.parse(json['date_created']),
        imageUrl: json['image_url'],
        category: json['category'] ?? 'General',
      );
}

// class ProductController {
//   Future<List<Product>> fetchProducts() async {
//     final response = await http.get(Uri.parse('https://agri-farms-db-default-rtdb.firebaseio.com/api/products'));

//     if (response.statusCode == 200) {
//       final List<dynamic> data = json.decode(response.body);
//       return data.map((json) => Product.fromJson(json)).toList();
//     } else {
//       throw Exception('Failed to load products');
//     }
//   }
// }

class ProductController {
  Future<List<Product>> fetchProducts() async {
    final String response =
        await rootBundle.loadString('lib/asset/produce.json');
    final List<dynamic> data = json.decode(response);
    return data.map((json) => Product.fromJson(json)).toList();
  }
}
