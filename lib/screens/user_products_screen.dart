import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/model/providers/product_list_provider.dart';
import 'package:shop_app/screens/add_edit_product_screen.dart';
import 'package:shop_app/widgets/drawer.dart';
import 'package:shop_app/widgets/user_product_item.dart';

class UserProductsScreen extends StatelessWidget {
  static const String routeName = 'UserProductsScreen';
  static Route getRoute(RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => UserProductsScreen());
  }

  Future futureOperation(BuildContext context) =>
      Provider.of<ProductListProvider>(context, listen: false).fetchProducts(
          true); //true to only get products specific to this user

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        title: const Text('Your Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              //to add a product
              Navigator.of(context).pushNamed(AddOrEditProductScreen.routeName);
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: futureOperation(context),
        builder: (context, dataSnapshot) {
          if (dataSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return RefreshIndicator(
            //this method should returns Future<void> i.e we should return the call or just use async await as
            //using async also returns a Future<void> even if we don't specify the return
            onRefresh: () => futureOperation(context),

            child: Consumer<ProductListProvider>(
              builder: (context, productsProvider, child) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    return UserProductItemWidget(
                        productsProvider.loadedProducts[index].id,
                        productsProvider.loadedProducts[index].title,
                        productsProvider.loadedProducts[index].imageUrl);
                  },
                  itemCount: productsProvider.loadedProducts.length,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
