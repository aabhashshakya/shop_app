import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/product_list_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  static const String routeName = 'ProductDetailScreen';
  static Route getRoute(RouteSettings settings) {
    return MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
              productID: settings.arguments,
            ));
  }

  final String productID;

  ProductDetailScreen({@required this.productID});

  @override
  Widget build(BuildContext context) {
    var product = Provider.of<ProductListProvider>(context, listen: false)
        .getProductById(productID);
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 300,
              width: double.infinity,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              '\$${product.price}',
              style: TextStyle(color: Colors.grey, fontSize: 20),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              width: double.infinity,
              child: Text(
                '${product.description}',
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}
