import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shop_app/screens/add_edit_product_screen.dart';
import 'package:shop_app/screens/auth_screen.dart';
import 'package:shop_app/screens/cart_screen.dart';
import 'package:shop_app/screens/orders_screen.dart';
import 'package:shop_app/screens/product_detail_screen.dart';
import 'package:shop_app/screens/products_overview_screen.dart';
import 'package:shop_app/screens/user_products_screen.dart';

class MyRoutes {
  static Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case ProductsOverviewScreen.routeName:
        return ProductsOverviewScreen.getRoute(settings);
      case ProductDetailScreen.routeName:
        return ProductDetailScreen.getRoute(settings);
      case CartScreen.routeName:
        return CartScreen.getRoute(settings);
      case OrdersScreen.routeName:
        return OrdersScreen.getRoute(settings);
      case UserProductsScreen.routeName:
        return UserProductsScreen.getRoute(settings);
      case AddOrEditProductScreen.routeName:
        return AddOrEditProductScreen.getRoute(settings);
      case AuthScreen.routeName:
        return AuthScreen.getRoute(settings);

      default:
        return MaterialPageRoute(
            builder: (_) => Scaffold(
                  body: Center(
                    child: Text(
                      'Error! Destination not found!!!',
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                ));
    }
  }
}
